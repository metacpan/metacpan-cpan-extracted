#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: Werkzeuge rund um Dateien, Journal und Zeit, nachgezogen aus
# einer Messrunde mit Timer- und Log-Aufgaben. Behauptet wird, dass
# sie antworten wie Debian 12: ls zeigt . und .. (-a), versteckt Punkt-Dateien,
# zeigt leere Verzeichnisse und -R rekursiv, *.wants als Verweise; find liefert auch
# Verzeichnisse, kennt -maxdepth, -exec, -printf, -o, -not, -path, -newermt; das
# Journal reicht so weit zurueck wie seine Dateien, kennt --since, -o short-iso,
# --list-boots, --file, und ein dauerhaft gestellter journald uebernimmt das
# Laufzeit-Journal; timedatectl, file, dpkg, bash -c; disable entfernt einen
# vorhandenen Verweis auch ohne [Install]; ein oneshot-Lauf legt seine Ergebnisse an.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $start = {
    srv => {
        type   => 'linux',
        users  => { export => { uid => 1030, groups => ['export'] } },
        dirs   => { '/var/lib/export' => { owner => 'export', group => 'export', mode => '0750' }, '/var/lib/export/leer' => { mode => '0700' } },
        files  => {
            '/var/lib/export/tmp/.keep'  => { content => '', owner => 'export', group => 'export', mode => '0640' },
            '/var/lib/export/a.csv'      => { content => "x\n", owner => 'export', mtime => 'Oct 19 01:00' },
            '/opt/app/bin/app'           => { size => '2M', mode => '0755', content => '' },
            '/opt/app/run.sh'            => { content => "#!/bin/sh\necho hi\n", mode => '0755' },
            '/etc/systemd/system/job.service' => "[Unit]\nDescription=Job\n\n[Service]\nType=oneshot\nExecStart=/opt/app/bin/app\n",
            '/etc/systemd/journald.conf' => "[Journal]\n#Storage=auto\n",
            '/run/log/journal/5c1e7d2a9b8f4e3d8c6b4a2f0e1d3c5b/system.journal' => { size => '24M', group => 'systemd-journal', mode => '0640', open_by => 'systemd-journald' },
        },
        services => {
            job => { active => JSON::MaybeXS::false(), enabled => $T, unit => '/etc/systemd/system/job.service',
                unit_loaded => "[Unit]\nDescription=Job\n\n[Service]\nType=oneshot\nExecStart=/opt/app/bin/app\n",
                creates => { '/var/lib/export/b.csv' => { size => '1M', owner => 'export' } }, run_journal => ['srv app[77]: 12 records written'] },
            nginx => { active => $T, description => 'nginx' },
            'systemd-journald' => { active => $T, config => '/etc/systemd/journald.conf', running => "[Journal]\n#Storage=auto\n" },
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'srv', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}

# --- ls ----------------------------------------------------------------------
{
    fresh();
    my $o = sh('ls -la /var/lib/export');
    like( $o, qr/^drwxr-x--- 2 export   export       4096 Oct 20 09:00 \.$/m, 'ls -la: . mit den Rechten des Verzeichnisses' );
    like( $o, qr/^d\S+ 2 root\s+root\s+4096 Oct 20 09:00 \.\.$/m, '... und ..' );
    is( sh('ls /var/lib/export/tmp'), '', 'Punkt-Dateien ohne -a versteckt' );
    is( sh('ls -A /var/lib/export/tmp'), '.keep', '-A zeigt sie' );
    like( sh('ls -la /var/lib/export/leer'), qr/\Atotal 8\ndrwx------ .* \.\n.* \.\.\z/, 'leeres Verzeichnis: total, . und ..' );
    like( sh('ls -R /var/lib/export'), qr/\A\/var\/lib\/export:\na\.csv\nleer\ntmp\n\n\/var\/lib\/export\/leer:\n\n\/var\/lib\/export\/tmp:\z/, 'ls -R' );
    like( sh('ls -l /etc/systemd/system/multi-user.target.wants'), qr/^lrwxrwxrwx .* job\.service -> \/etc\/systemd\/system\/job\.service$/m, '*.wants: Verweise der enabled Units' );
}

# --- find --------------------------------------------------------------------
{
    fresh();
    is( sh('find /var/lib/export -maxdepth 1'), "/var/lib/export\n/var/lib/export/a.csv\n/var/lib/export/leer\n/var/lib/export/tmp", 'find: Wurzel und Verzeichnisse, -maxdepth' );
    is( sh('find /var/lib/export -type d'), "/var/lib/export\n/var/lib/export/leer\n/var/lib/export/tmp", '-type d' );
    like( sh('find /var/lib/export -type d -exec ls -ld {} +'), qr/\Adrwxr-x--- 2 export .* \/var\/lib\/export\n/, '-exec … {} +' );
    is( sh(q{find /var/lib/export -name '*.csv' -printf '%f %u %m\n'}), 'a.csv export 644', '-printf' );
    is( sh(q{find /var/lib/export -name '*.csv' -o -name '.keep'}), "/var/lib/export/a.csv\n/var/lib/export/tmp/.keep", '-o' );
    is( sh(q{find /var/lib/export -type f -not -path '*/tmp/*'}), '/var/lib/export/a.csv', '-not -path' );
    is( sh(q{find /var/lib/export -type f -newermt '2026-10-19 12:00'}), '/var/lib/export/tmp/.keep', '-newermt' );
    my ( $o, $ok ) = sh('find /var/lib/export -bogus');
    is( $o, "find: unknown predicate `-bogus'", 'unbekanntes Praedikat wie GNU find' );
}

# --- Journal -----------------------------------------------------------------
{
    fresh();
    is( sh('journalctl --disk-usage'), 'Archived and active journals take up 24M in the file system.', 'disk-usage zaehlt /run/log/journal mit' );
    my ( $o, $ok ) = sh('journalctl --no-legend');
    ok( !$ok, 'unbekannte Option' );
    is( $o, "journalctl: unrecognized option '--no-legend'", '... Meldung wie journalctl' );
    like( sh('journalctl -n 1'), qr/\AOct 20 14:00:00 srv /, 'Journal reicht so weit wie seine Dateien' );
    like( sh('journalctl --list-boots'), qr/\A 0 [0-9a-f]{32} Tue 2026-10-20 14:00:00 CEST\x{2014}Tue 2026-10-20 14:00:00 CEST\z/, '--list-boots' );
    like( sh('journalctl -n 1 -o short-iso'), qr/\A2026-10-20T14:00:00\+0200 srv /, '-o short-iso' );
    is( sh('journalctl --since 2026-10-21'), '-- No entries --', '--since' );
    ( $o, $ok ) = sh('journalctl --since gestern');
    is( $o, 'Failed to parse timestamp: gestern', '... ungueltig' );
    sh(q{printf '[Journal]\nStorage=persistent\n' > /etc/systemd/journald.conf});
    sh('systemctl restart systemd-journald');
    ok( $state->{srv}{files}{'/var/log/journal/5c1e7d2a9b8f4e3d8c6b4a2f0e1d3c5b/system.journal'}, 'persistent: Journal liegt jetzt unter /var/log/journal' );
    ok( !$state->{srv}{files}{'/run/log/journal/5c1e7d2a9b8f4e3d8c6b4a2f0e1d3c5b/system.journal'}, '... das Laufzeit-Journal ist uebernommen' );
    like( sh('ls -l /var/log/journal/5c1e7d2a9b8f4e3d8c6b4a2f0e1d3c5b'), qr/system\.journal$/, '... und sichtbar' );
    fresh();
    sh('mkdir -p /var/log/journal');
    sh('journalctl --flush');
    ok( $state->{srv}{files}{'/var/log/journal/5c1e7d2a9b8f4e3d8c6b4a2f0e1d3c5b/system.journal'}, 'Storage=auto mit Verzeichnis: --flush uebernimmt' );
}

# --- timedatectl, file, dpkg, bash -c ------------------------------------------
{
    fresh();
    like( sh('timedatectl'), qr/^\s+Local time: Tue 2026-10-20 14:00:00 CEST$/m, 'timedatectl: Ortszeit' );
    like( sh('timedatectl'), qr/^\s+Time zone: Europe\/Berlin \(CEST, \+0200\)$/m, '... Zeitzone' );
    is( sh('timedatectl show -p Timezone --value'), 'Europe/Berlin', 'timedatectl show' );
    sh('timedatectl set-timezone UTC');
    is( $state->{srv}{timezone}, 'UTC', 'set-timezone aendert den Zustand' );
    like( sh(q{systemd-analyze calendar '07:00'}), qr/Next elapse: Wed 2026-10-21 07:00:00 UTC/, '... und die Ortszeit der Kalender' );
    fresh();
    # cat-config: Hauptdatei, dann Drop-ins nach Dateiname; /etc verdeckt /usr/lib
    $state->{srv}{files}{'/etc/systemd/journald.conf'}                 = "[Journal]\nStorage=auto\n";
    $state->{srv}{files}{'/usr/lib/systemd/journald.conf.d/10-a.conf'} = "[Journal]\nCompress=no\n";
    $state->{srv}{files}{'/usr/lib/systemd/journald.conf.d/20-b.conf'} = "[Journal]\nSystemMaxUse=9G\n";
    $state->{srv}{files}{'/etc/systemd/journald.conf.d/20-b.conf'}     = "[Journal]\nSystemMaxUse=1G\n";
    is( sh('systemd-analyze cat-config systemd/journald.conf'),
        "# /etc/systemd/journald.conf\n[Journal]\nStorage=auto\n\n# /usr/lib/systemd/journald.conf.d/10-a.conf\n[Journal]\nCompress=no\n\n# /etc/systemd/journald.conf.d/20-b.conf\n[Journal]\nSystemMaxUse=1G",
        'systemd-analyze cat-config: Datei und Drop-ins' );
    is( sh('systemd-analyze cat-config --no-pager /etc/systemd/journald.conf'), sh('systemd-analyze cat-config systemd/journald.conf'), '... auch mit absolutem Pfad' );
    fresh();
    like( sh('file /opt/app/bin/app'), qr/: ELF 64-bit LSB pie executable/, 'file: Programm' );
    is( sh('file /opt/app/run.sh'), '/opt/app/run.sh: POSIX shell script, ASCII text executable', 'file: Skript' );
    is( sh('file /nicht/da'), "/nicht/da: cannot open `/nicht/da' (No such file or directory)", 'file: fehlt' );
    like( sh('dpkg -L logrotate'), qr{^/lib/systemd/system/logrotate\.timer$}m, 'dpkg -L logrotate' );
    is( sh('dpkg -S /usr/sbin/logrotate'), 'logrotate: /usr/sbin/logrotate', 'dpkg -S' );
    is( sh(q{bash -c 'echo hallo'}), 'hallo', 'bash -c' );
}

# --- disable ohne [Install], oneshot legt an -------------------------------------
{
    fresh();
    is( sh('systemctl is-enabled job'), 'enabled', 'Unit ohne [Install] mit vorhandenem Verweis: enabled' );
    like( sh('systemctl disable job'), qr{\ARemoved "/etc/systemd/system/multi-user\.target\.wants/job\.service"\.\z}, 'disable entfernt den Verweis' );
    is( sh('systemctl is-enabled job'), 'static', '... danach static' );
    sh('systemctl start job');
    ok( $state->{srv}{files}{'/var/lib/export/b.csv'}, 'oneshot-Lauf legt sein Ergebnis an' );
    like( sh('journalctl -u job'), qr/app\[77\]: 12 records written\n.*Deactivated successfully/s, '... und schreibt ins Journal' );
}

# Kleine Werkzeuge, die in den Bench-Laeufen still Falsches lieferten:
# printf nahm nur die erste Runde des Formats, tr kannte keine Bereiche/Klassen/-c,
# head -n -1 gab eine Zeile, wc nannte keine Dateinamen.
subtest 'printf, tr, head/tail, wc, md5sum wie coreutils' => sub {
    fresh();
    is( sh(q{printf '%s\n' a b c}), "a\nb\nc", 'printf: Format wiederholt sich' );
    is( sh(q{printf '%02x %d %5.1f|%-4s|%c\n' "'A" 42 3.14159 ab xyz}), '41 42   3.1|ab  |x', 'printf: %x mit Zeichencode, Breiten' );
    is( sh(q{printf '%d\n' zwei}), "0\nbash: printf: zwei: invalid number", 'printf: keine Zahl' );
    is( sh(q{echo 'www-2026-08-01.tar.gz' | tr -c '[:print:]\n' '?'}), 'www-2026-08-01.tar.gz', 'tr -c mit Klasse' );
    is( sh(q{echo abc | tr a-c A-C}), 'ABC', 'tr Bereich' );
    is( sh(q{echo abc123 | tr -d '[:digit:]'}), 'abc', 'tr -d Klasse' );
    is( sh(q{echo 'a   b' | tr -s ' '}), 'a b', 'tr -s' );
    is( sh(q{echo hallo | tr a-z A}), 'AAAAA', 'tr: Satz 2 mit dem letzten Zeichen aufgefuellt' );
    is( sh(q{printf 'a\nb\nc\n' | head -n -1}), "a\nb", 'head -n -1: alles ausser der letzten Zeile' );
    is( sh(q{printf 'a\nb\nc\n' | tail -n +2}), "b\nc", 'tail -n +2: ab Zeile 2' );
    is( sh(q{wc -l /var/lib/export/a.csv /opt/app/run.sh}), "1 /var/lib/export/a.csv\n2 /opt/app/run.sh\n3 total", 'wc mit mehreren Dateien' );
    is( sh(q{printf 'ab cd\n' | wc -lw}), '1 2', 'wc -lw' );
    is( sh(q{md5sum /opt/app/run.sh}), '46bbbe8aa98cc0714426e948474eaaf4  /opt/app/run.sh', 'md5sum' );
    my ( $o, $ok, $gap ) = sh(q{md5sum /opt/app/bin/app});
    ok( !$gap, 'md5sum einer leeren Datei: gerechnet' );
};

done_testing;
