#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: was Alltagsaufgaben im Terminal
# brauchen. Behauptet wird, dass diese Befehle antworten und wirken wie auf Debian 12:
# mkdir (-p legt Eltern an, ohne -p fehlt der Elternordner; -m; Rechte; setgid
# erbt), rm laesst das Verzeichnis stehen, umask (eingebaut), Anlegen als Benutzer
# ohne Root-Rechte (Schreibrecht am Verzeichnis, Eigentuemer, Gruppe eines
# setgid-Verzeichnisses), install, crontab DATEI|- (mit Syntaxpruefung),
# useradd/groupadd/addgroup/adduser --system, getent group nur fuer vorhandene
# Gruppen, mv mehrerer Quellen in ein Verzeichnis, ls -t, tar -T/--remove-files,
# ein oneshot-Dienst mit Shell-Skript als ExecStart fuehrt das Skript aus, su in
# ein Konto mit nologin.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $F = JSON::MaybeXS::false();
my $start = {
    srv => {
        type   => 'linux',
        oneshot_scripts => $T,
        check_accounts  => $T,
        users  => { anna => { uid => 1001, groups => [qw( anna redaktion )], shell => '/bin/bash' },
                    ben  => { uid => 1002, groups => ['ben'], shell => '/bin/bash' },
                    shop => { uid => 1003, groups => ['shop'], shell => '/bin/bash' },
                    dienst => { uid => 998, groups => ['dienst'], shell => '/usr/sbin/nologin' } },
        groups => { anna => { gid => 1001 }, ben => { gid => 1002 }, redaktion => { gid => 1010 }, shop => { gid => 1003 },
                    dienst => { gid => 998 }, leer => { gid => 1020 } },
        dirs   => { '/srv/team' => { owner => 'root', group => 'redaktion', mode => '2770' },
                    '/srv/zu'   => { owner => 'root', group => 'root', mode => '0755' } },
        files  => {
            '/srv/daten/a.csv' => { content => "a\n", mtime => 'Sep 01 10:00' },
            '/srv/daten/b.csv' => { content => "b\n", mtime => 'Oct 19 10:00' },
            '/srv/daten/c.csv' => { content => "c\n", mtime => 'Oct 02 10:00' },
            '/srv/einzeln/nur.txt' => "x\n",
            '/var/spool/cron/crontabs/shop' => { content => "# m h dom mon dow command\n0 3 * * * /opt/shop/bin/export\n", owner => 'shop', group => 'crontab', mode => '0600' },
            '/usr/local/bin/aufraeumen.sh' => { mode => '0755', content => "#!/bin/bash\nfind /srv/daten -name '*.csv' -mtime +14 -delete\n" },
            '/usr/local/bin/kaputt.sh'     => { mode => '0755', content => "#!/bin/bash\nexit 3\n" },
            '/etc/systemd/system/aufraeumen.service' => "[Unit]\nDescription=Aufraeumen\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/aufraeumen.sh\n",
            '/etc/systemd/system/kaputt.service'     => "[Unit]\nDescription=Kaputt\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/kaputt.sh\n",
            '/etc/systemd/system/schreiber.service'  => "[Unit]\nDescription=Schreiber\n\n[Service]\nType=oneshot\nUser=ben\nExecStart=/usr/local/bin/schreiber.sh\n",
            '/usr/local/bin/schreiber.sh' => { mode => '0755', content => "#!/bin/sh\ntouch /srv/zu/von-ben\n" },
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
sub dev { $state->{srv} }

# --- mkdir, rm --------------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('mkdir /srv/neu/a');
    ok( !$ok, 'mkdir ohne -p: Elternordner fehlt' );
    is( $o, "mkdir: cannot create directory '/srv/neu/a': No such file or directory", '... Meldung wie coreutils' );
    ( $o, $ok ) = sh('mkdir -p /srv/neu/a/b && ls -ld /srv/neu /srv/neu/a');
    ok( $ok, 'mkdir -p legt die Eltern an' ) or diag $o;
    like( $o, qr{^drwxr-xr-x .* /srv/neu$}m, '... auch der Elternordner ist ein Verzeichnis' );
    ( $o, $ok ) = sh('mkdir /srv/neu');
    is( $o, "mkdir: cannot create directory '/srv/neu': File exists", 'mkdir auf Vorhandenes: File exists' );
    ok( scalar sh('mkdir -p /srv/neu') eq '' && ( sh('mkdir -p /srv/neu') )[1], 'mkdir -p auf Vorhandenes: still' );
    sh('mkdir -m 0750 /srv/geheim');
    like( sh('stat -c %a /srv/geheim'), qr/\A750\z/, 'mkdir -m setzt die Rechte' );
    sh('mkdir /srv/team/projekt');
    is( sh('stat -c "%a %G" /srv/team/projekt'), '2755 redaktion', 'mkdir in setgid-Verzeichnis: Gruppe und setgid geerbt' );

    sh('rm /srv/einzeln/nur.txt');
    ( $o, $ok ) = sh('ls -la /srv/einzeln');
    ok( $ok, 'rm der letzten Datei: das Verzeichnis bleibt' ) or diag $o;
    like( $o, qr/\Atotal 8\n/, '... leer' );
    sh('rm -r /srv/neu');
    ( $o, $ok ) = sh('ls /srv/neu');
    ok( !$ok, 'rm -r entfernt auch angelegte Verzeichnisse' );
    my @diff = grep { !grep { /\A_/ } @{ $_->{path} } } diff( $start, $state );
    ok( !grep( { $_->{path}[2] eq '/srv/einzeln' } @diff ), '... und das stehengebliebene Verzeichnis ist keine Aenderung' );
}

# --- umask, Anlegen als Benutzer ----------------------------------------------
{
    fresh();
    is( sh('umask'), '0022', 'umask zeigt 0022' );
    is( sh('umask -S'), 'u=rwx,g=rx,o=rx', 'umask -S' );
    is( sh('umask 027; umask; touch /srv/u1; stat -c %a /srv/u1'), "0027\n640", 'umask 027 wirkt auf neue Dateien' );
    is( sh('umask 007; mkdir /srv/u2; stat -c %a /srv/u2'), '770', '... und auf neue Verzeichnisse' );
    is( sh('touch /srv/u3; stat -c %a /srv/u3'), '644', 'umask gilt nur in ihrer Shell' );
    is( sh('cd /srv && echo rel > rel.txt && cat /srv/rel.txt'), 'rel', 'Umleitung in einen relativen Pfad nach cd' );
    my ( $o, $ok ) = sh('umask 999');
    ok( !$ok, 'umask mit Unsinn scheitert' );
    is( $o, 'bash: umask: 999: octal number out of range', '... Meldung wie bash' );

    ( $o, $ok ) = sh(q{su - ben -c 'touch /srv/zu/x'});
    ok( !$ok, 'Benutzer ohne Schreibrecht am Verzeichnis: touch scheitert' );
    is( $o, "touch: cannot touch '/srv/zu/x': Permission denied", '... Meldung wie coreutils' );
    ( $o, $ok ) = sh(q{su - ben -c 'echo hi > /srv/zu/y'});
    ok( !$ok, '... ebenso eine Umleitung' );
    like( $o, qr{/srv/zu/y: Permission denied}, '... Permission denied' );
    ok( !exists dev()->{files}{'/srv/zu/x'} && !exists dev()->{files}{'/srv/zu/y'}, '... nichts angelegt' );
    ( $o, $ok ) = sh(q{su - ben -c 'mkdir /srv/zu/d'});
    is( $o, "mkdir: cannot create directory '/srv/zu/d': Permission denied", '... mkdir: Permission denied' );

    ( $o, $ok ) = sh(q{su - anna -c 'touch /srv/team/notiz && echo text >> /srv/team/notiz'});
    ok( $ok, 'Mitglied der Gruppe schreibt ins setgid-Verzeichnis' ) or diag $o;
    is( sh('stat -c "%U %G %a" /srv/team/notiz'), 'anna redaktion 644', '... Datei gehoert anna, Gruppe des Verzeichnisses' );
    is( sh('cat /srv/team/notiz'), 'text', '... mit Inhalt' );
    ( $o, $ok ) = sh(q{su - ben -c 'touch /srv/team/fremd'});
    ok( !$ok, 'Nicht-Mitglied: Permission denied' );
    ( $o, $ok ) = sh(q{sudo -u ben touch /srv/team/fremd2});
    ok( !$ok, '... auch ueber sudo -u' );
    ( $o, $ok ) = sh(q{su - anna -c 'umask 002; touch /srv/team/geteilt'});
    is( sh('stat -c "%U %G %a" /srv/team/geteilt'), 'anna redaktion 664', 'umask 002 des Benutzers: gruppenschreibbar' );
    ( $o, $ok ) = sh(q{su - ben -c 'echo x >> /srv/team/notiz'});
    ok( !$ok, 'fremde Datei ohne Schreibrecht: scheitert' );
    ( $o, $ok ) = sh(q{su - ben -c 'touch /tmp/ben.txt'});
    ok( $ok, '/tmp ist fuer alle schreibbar' );
    is( sh('stat -c "%U %G" /tmp/ben.txt'), 'ben ben', '... Datei gehoert ben' );

    ( $o, $ok ) = sh(q{su - dienst -c 'true'});
    ok( !$ok, 'su in ein Konto mit nologin scheitert' );
    is( $o, 'This account is currently not available.', '... Meldung von nologin' );
    ( $o, $ok ) = sh(q{su -s /bin/sh dienst -c 'true'});
    ok( $ok, '... mit -s /bin/sh geht es' );
    ( $o, $ok ) = sh(q{su - niemand -c 'true'});
    ok( !$ok, 'su in ein unbekanntes Konto scheitert' );
}

# --- install --------------------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('install -m 0755 -o root -g root /srv/daten/a.csv /usr/local/bin/a');
    ok( $ok, 'install DATEI ZIEL' ) or diag $o;
    is( sh('stat -c "%U %G %a" /usr/local/bin/a; cat /usr/local/bin/a'), "root root 755\na", '... Rechte, Eigentuemer, Inhalt' );
    ( $o, $ok ) = sh('install -d -m 0750 -o anna -g redaktion /srv/x/y');
    ok( $ok, 'install -d legt Verzeichnisse an (mit Eltern)' ) or diag $o;
    is( sh('stat -c "%U %G %a" /srv/x/y'), 'anna redaktion 750', '... mit Rechten und Eigentuemer' );
    ( $o, $ok ) = sh('install -D -m 0644 /srv/daten/b.csv /srv/tief/drin/b.csv && ls /srv/tief/drin');
    is( $o, 'b.csv', 'install -D legt die Eltern des Ziels an' );
    ( $o, $ok ) = sh('install /srv/nichts /srv/z');
    is( $o, "install: cannot stat '/srv/nichts': No such file or directory", 'install: Quelle fehlt' );
    ( $o, $ok ) = sh('install -o niemand /srv/daten/a.csv /srv/z');
    is( $o, "install: invalid user 'niemand'", 'install: unbekannter Benutzer' );
    ( $o, $ok ) = sh('install -g niemand /srv/daten/a.csv /srv/z');
    is( $o, "install: invalid group 'niemand'", 'install: unbekannte Gruppe' );
    ( $o, $ok ) = sh('install /srv/daten/a.csv /srv/daten/b.csv /srv/zu');
    ok( $ok && sh('ls /srv/zu') eq "a.csv\nb.csv", 'install mehrerer Dateien in ein Verzeichnis' );
    is( sh('stat -c %a /srv/zu/a.csv'), '755', '... Vorgabe 0755' );
}

# --- crontab --------------------------------------------------------------------
{
    fresh();
    is( sh('crontab -u shop -l'), "# m h dom mon dow command\n0 3 * * * /opt/shop/bin/export", 'crontab -u shop -l' );
    my ( $o, $ok ) = sh(q{(crontab -u shop -l; echo '*/10 * * * * /opt/shop/bin/cache') | crontab -u shop -});
    ok( $ok, '(crontab -l; echo …) | crontab -: Subshell in eine Pipe' ) or diag $o;
    is( sh('crontab -u shop -l'), "# m h dom mon dow command\n0 3 * * * /opt/shop/bin/export\n*/10 * * * * /opt/shop/bin/cache", '... ergaenzt' );
    is( sh(q{X=1; (X=2; cd /srv; echo $X); echo $X; pwd}), "2\n1\n/root", 'Subshell: Variablen und cd bleiben drinnen' );
    is( sh(q{(echo "a)b"; echo 'c)'); echo d}), "a)b\nc)\nd", '... Klammern in Anfuehrungszeichen' );
    fresh();
    ( $o, $ok ) = sh(q{crontab -u shop -l > /tmp/c && echo '*/10 * * * * /opt/shop/bin/cache' >> /tmp/c && crontab -u shop /tmp/c});
    ok( $ok, 'crontab -u shop DATEI' ) or diag $o;
    is( sh('crontab -u shop -l'), "# m h dom mon dow command\n0 3 * * * /opt/shop/bin/export\n*/10 * * * * /opt/shop/bin/cache", '... ersetzt den ganzen crontab' );
    is( sh('stat -c "%U %G %a" /var/spool/cron/crontabs/shop'), 'shop crontab 600', '... Datei wie cron sie anlegt' );
    like( sh('head -2 /var/spool/cron/crontabs/shop'), qr{\A# DO NOT EDIT THIS FILE - edit the master and reinstall\.\n# \(/tmp/c installed on }, '... mit dem Kopf von crontab' );
    unlike( sh('crontab -u shop -l'), qr/DO NOT EDIT/, '... den crontab -l nicht zeigt' );
    ( $o, $ok ) = sh(q{echo '5 4 * * * /bin/true' | crontab -});
    ok( $ok, 'crontab - liest die Eingabe' ) or diag $o;
    is( sh('crontab -l'), '5 4 * * * /bin/true', '... crontab von root' );
    ( $o, $ok ) = sh(q{echo '61 4 * * * /bin/true' | crontab -u shop -});
    ok( !$ok, 'ungueltige Minute: nicht installiert' );
    is( $o, qq{"-":0: bad minute\nerrors in crontab file, can't install.}, '... Meldung wie Debian-cron' );
    ( $o, $ok ) = sh(q{printf '0 3 * * * /x\n0 3 * * /y\n' > /tmp/d; crontab -u shop /tmp/d});
    is( $o, qq{"/tmp/d":1: bad day-of-week\nerrors in crontab file, can't install.}, '... zu wenige Felder' );
    like( sh('crontab -u shop -l'), qr{/bin/export}, '... der alte crontab bleibt' );
    ( $o, $ok ) = sh(q{printf 'MAILTO=""\n@daily /x\n' | crontab -u shop -});
    ok( $ok, 'Variablen und @daily sind gueltig' ) or diag $o;
    ( $o, $ok ) = sh('crontab -u niemand -l');
    is( $o, "crontab: user `niemand' unknown", 'unbekannter Benutzer' );
}

# --- Benutzer und Gruppen ---------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('groupadd projekt && getent group projekt');
    is( $o, 'projekt:x:1021:', 'groupadd: naechste freie GID ab 1000' );
    is( ( sh('groupadd projekt') )[0], "groupadd: group 'projekt' already exists", 'groupadd: vorhanden' );
    is( sh('groupadd -r sammler; getent group sammler'), 'sammler:x:999:', 'groupadd -r: Systemgruppe unter 1000' );
    ( $o, $ok ) = sh('getent group gibtsnicht');
    ok( !$ok && $o eq '', 'getent group: unbekannte Gruppe liefert nichts (Exit 2)' );
    is( sh('getent group leer'), 'leer:x:1020:', 'getent group: Gruppe ohne Mitglieder' );

    ( $o, $ok ) = sh('useradd -m -s /bin/bash -G redaktion carla && id carla && getent passwd carla');
    ok( $ok, 'useradd -m -s -G' ) or diag $o;
    is( $o, "uid=1004(carla) gid=1004(carla) groups=1004(carla),1010(redaktion)\ncarla:x:1004:1004::/home/carla:/bin/bash", '... uid/gid, Gruppe gleichen Namens, Zusatzgruppe' );
    is( sh('stat -c "%U %G" /home/carla'), 'carla carla', '... Heimatverzeichnis' );
    is( ( sh('useradd carla') )[0], "useradd: user 'carla' already exists", 'useradd: vorhanden' );
    is( ( sh('useradd -G gibtsnicht dora') )[0], "useradd: group 'gibtsnicht' does not exist", 'useradd: Gruppe fehlt' );
    ( $o, $ok ) = sh('useradd --system --no-create-home --home-dir /var/lib/sammler --shell /usr/sbin/nologin -g sammler sammler && getent passwd sammler');
    is( $o, 'sammler:x:999:999::/var/lib/sammler:/usr/sbin/nologin', 'useradd --system: UID unter 1000, Gruppe -g' );
    ok( !( sh('ls -d /var/lib/sammler') )[1], '... ohne Heimatverzeichnis' );
    is( sh('useradd emil; getent passwd emil'), 'emil:x:1005:1005::/home/emil:/bin/sh', 'useradd ohne -s: /bin/sh wie Debian' );
    ( $o, $ok ) = sh('addgroup --system web && adduser --system --ingroup web --no-create-home --home /srv/web web && id web');
    ok( $ok, 'addgroup --system, adduser --system' ) or diag $o;
    like( $o, qr/\Auid=\d{3}\(web\) gid=\d{3}\(web\) groups=\d{3}\(web\)\z/, '... Systemkonto' );
    is( sh('adduser anna ben; id anna'), "Adding user `anna' to group `ben' ...\nDone.\nuid=1001(anna) gid=1001(anna) groups=1001(anna),1010(redaktion),1002(ben)", 'adduser BENUTZER GRUPPE' );
    ( $o, $ok, my $gap ) = sh('adduser fritz');
    ok( defined $gap, 'adduser interaktiv: Luecke der Simulation' );
}

# --- mv, ls -t ------------------------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('mkdir /srv/alt && mv /srv/daten/a.csv /srv/daten/c.csv /srv/alt/ && ls /srv/alt /srv/daten');
    ok( $ok, 'mv mehrerer Quellen in ein Verzeichnis' ) or diag $o;
    is( $o, "/srv/alt:\na.csv\nc.csv\n\n/srv/daten:\nb.csv", '... angekommen' );
    sh('mv /srv/daten/b.csv /srv/alt/');
    ok( exists dev()->{files}{'/srv/alt/b.csv'}, 'mv datei verzeichnis/: ohne doppelten Schraegstrich' );
    sh('mv /srv/alt/b.csv /srv/daten/b.csv');
    is( sh('cd /srv/daten && mv b.csv ../alt/ && ls ../alt/ && cat /srv/alt/./../alt/b.csv && mv ../alt/b.csv .'), "a.csv\nb.csv\nc.csv\nb", 'Pfade mit .. und .' );
    ( $o, $ok ) = sh('mv /srv/daten/b.csv /srv/alt/a.csv /srv/nichtda');
    is( $o, "mv: target '/srv/nichtda': No such file or directory", 'mv mehrerer Quellen: Ziel fehlt' );
    fresh();
    is( sh('ls -t /srv/daten'), "b.csv\nc.csv\na.csv", 'ls -t: neueste zuerst' );
    is( sh('ls -tr /srv/daten'), "a.csv\nc.csv\nb.csv", 'ls -tr: aelteste zuerst' );
    like( sh('ls -lt /srv/daten'), qr/b\.csv\n.*c\.csv\n.*a\.csv\z/, 'ls -lt' );
}

# --- tar -T, --remove-files ---------------------------------------------------------
subtest 'tar -T, --remove-files' => sub {
    fresh();
    my ( $o, $ok ) = sh(q{find /srv/daten -name '*.csv' -mtime +14 > /tmp/liste && tar -czf /srv/alt.tar.gz -T /tmp/liste && tar -tzf /srv/alt.tar.gz});
    ok( $ok, 'tar -T liest die Mitglieder aus einer Datei' ) or diag $o;
    is( $o, "tar: Removing leading `/' from member names\nsrv/daten/a.csv\nsrv/daten/c.csv", '... die alten Dateien' );
    ( $o, $ok ) = sh(q{find /srv/daten -name '*.csv' -mtime +14 | tar -czf /srv/alt2.tar.gz --files-from=- --remove-files && ls /srv/daten});
    ok( $ok, 'tar --files-from=- --remove-files' ) or diag $o;
    like( $o, qr/b\.csv\z/, '... die Quellen sind weg, das Neue bleibt' );
    ok( !exists dev()->{files}{'/srv/daten/a.csv'}, '... a.csv entfernt' );
};

# --- nachgezogen beim Bau der Faelle -------------------------------------------------------
subtest 'nachgezogen beim Bau der Faelle' => sub {
    fresh();
    dev()->{files}{'/srv/alt/README'} = { content => "x\n", mtime => 'Mar 12  2025' };
    is( sh('find /srv/alt -type f -mtime +14'), '/srv/alt/README', 'find -mtime: Zeit mit Jahr ("Mar 12  2025")' );
    is( sh(q{bash -c 'set -euo pipefail; echo "[${1:-}]"; false; echo nie'}), '[]', 'set -euo pipefail: kein Argument, errexit' );
    dev()->{files}{'/srv/app/daten/cache/s.bin'} = { size => '5M' };
    dev()->{files}{'/srv/app/daten/k.db'} = { size => '2M' };
    is( sh('tar -czf /srv/a.tgz --exclude=cache /srv/app/daten; tar -tzf /srv/a.tgz'), "tar: Removing leading `/' from member names\nsrv/app/daten/k.db", 'tar --exclude=cache trifft die Komponente' );
    is( sh('tar -czf /srv/b.tgz --exclude=/srv/app/daten/cache /srv/app/daten; tar -tzf /srv/b.tgz'), "tar: Removing leading `/' from member names\nsrv/app/daten/k.db", 'tar --exclude=/absoluter/pfad' );
    like( sh('ls -l /srv/a.tgz'), qr/root\s+(\d+) /, 'neues Archiv hat eine Groesse' );
    unlike( sh('ls -l /srv/a.tgz'), qr/root\s+0 /, '... nicht 0' );
    like( sh('stat /srv/team'), qr{\A  File: /srv/team\n.*directory\nAccess: \(2770/drwxrws---\)  Uid: \(    0/    root\)   Gid: \( 1010/redaktion\)\z}s, 'stat eines Verzeichnisses' );
};

# --- sort -h, PostgreSQL: DELETE mit Recht ------------------------------------------------
subtest 'sort -h, PostgreSQL: DELETE mit Recht' => sub {
    my $why = need_parts('Postgres');
    plan skip_all => $why if $why;
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    fresh();
    is( sh(q{printf '1.0G a\n200M b\n3G c\n12K d\n' | sort -h}), "12K d\n200M b\n1.0G a\n3G c", 'sort -h mit Einheiten' );
    is( sh(q[printf 'a{{b\na+b\nab\n' | grep -c '{{']), '1', 'grep (BRE): { steht fuer sich' );
    is( sh(q[printf 'a{{b\na+b\naab\n' | grep 'a+b']), 'a+b', 'grep (BRE): + steht fuer sich' );
    is( sh(q[printf 'a{{b\na+b\naab\n' | grep 'aa\|{']), "a{{b\naab", 'grep (BRE): \\| ist Alternative' );
    is( sh(q{printf 'a+b\naab\n' | grep -E 'a+b'}), "aab", 'grep -E: + wiederholt' );
    is_deeply( \@w, [], '... ohne Warnung' );
    my $pg = { db => { type => 'linux', users => { postgres => { uid => 105, groups => ['postgres'] } },
        services => { 'postgresql@15-main' => { active => $T, user => 'postgres' } },
        postgres => { service => 'postgresql@15-main', port => 5432, settings => { max_connections => 100 },
            hba_loaded => [ 'local all postgres peer', 'local all all trust' ],
            roles => { postgres => { superuser => $T, login => $T }, owner => {}, leser => { login => $T }, schreiber => { login => $T } },
            databases => { d => { owner => 'owner' } }, schemas => { 'd.s' => { owner => 'owner' } },
            tables => { 'd.s.t' => { owner => 'owner', n_live_tup => 7 } },
            grants => { 'database:d' => { leser => ['CONNECT'], schreiber => ['CONNECT'] }, 'schema:d.s' => { leser => ['USAGE'], schreiber => ['USAGE'] },
                'table:d.s.t' => { leser => ['SELECT'], schreiber => [qw( SELECT DELETE )] } }, activity => [] } } };
    my ( $o, $ok ) = run_command( $pg, 'db', q{psql -U leser -d d -c 'DELETE FROM s.t'} );
    ok( !$ok && $o =~ /permission denied for table s\.t/, 'DELETE ohne Recht: permission denied' ) or diag $o;
    ( $o, $ok ) = run_command( $pg, 'db', q{psql -U schreiber -d d -c 'DELETE FROM s.t'} );
    ok( $ok && $o eq 'DELETE 7', 'DELETE mit dem Recht DELETE (ohne Eigentuemer zu sein)' ) or diag $o;
    ( $o, $ok ) = run_command( $pg, 'db', q{psql -U schreiber -d d -c 'DROP TABLE s.t'} );
    ok( !$ok, 'DROP TABLE nur als Eigentuemer' );
    ( $o, $ok ) = run_command( $pg, 'db', 'systemctl reload postgresql && service postgresql reload' );
    ok( $ok, 'systemctl reload postgresql: wirkt auf den Cluster wie unter Debian' ) or diag $o;
    ok( !$pg->{db}{services}{'postgresql@15-main'}{restarts}, '... ohne Neustart' );
};

# --- needs env: Umgebung aus Environment= und EnvironmentFile= ----------------------------
{
    fresh();
    my $unit = "[Service]\nExecStart=/usr/bin/x\n";
    dev()->{files}{'/etc/systemd/system/x.service'} = $unit;
    dev()->{services}{x} = { active => $F, unit => '/etc/systemd/system/x.service', unit_loaded => $unit, exec => 'x',
        needs => [ { env => { X_URL => '\Adb://ok\z' }, log => ['Oct 20 09:12:03 srv x[1]: fatal: X_URL falsch'] } ] };
    my ( $o, $ok ) = sh('systemctl start x');
    ok( !$ok, 'ohne Umgebung: Start scheitert' );
    like( sh('journalctl -u x'), qr/X_URL falsch/, '... mit der Meldung der Bedingung' );
    sh(q{mkdir -p /etc/systemd/system/x.service.d && printf '[Service]\nEnvironmentFile=/etc/x.env\n' > /etc/systemd/system/x.service.d/e.conf && systemctl daemon-reload});
    ( $o, $ok ) = sh('systemctl start x');
    ok( !$ok, 'EnvironmentFile fehlt: Start scheitert' );
    like( sh('journalctl -u x'), qr/Failed to load environment files: No such file or directory/, '... wie systemd' );
    sh(q{printf '# Kommentar\nexport X_URL=db://falsch\nX_URL="db://ok"\n' > /etc/x.env});
    ( $o, $ok ) = sh('systemctl start x');
    ok( $ok, 'Datei mit Anfuehrungszeichen und Kommentar: Start gelingt' ) or diag $o;
    sh(q{systemctl stop x; printf '[Service]\nEnvironment=X_URL=db://ok\n' > /etc/systemd/system/x.service.d/e.conf && systemctl daemon-reload});
    ( $o, $ok ) = sh('systemctl start x');
    ok( $ok, 'Environment= im Drop-in: Start gelingt' ) or diag $o;
}

# --- User= der Unit, den es nicht gibt ------------------------------------------------------
{
    fresh();
    dev()->{files}{'/etc/systemd/system/y.service'} = "[Service]\nUser=ygibtsnicht\nExecStart=/opt/y/bin/y\n";
    my ( $o, $ok ) = sh('systemctl start y');
    ok( !$ok, 'User= unbekannt: Start scheitert' );
    like( sh('journalctl -u y'), qr/y\.service: Failed to determine user credentials: No such process/, '... 217/USER wie systemd' );
    dev()->{files}{'/etc/systemd/system/z.service'} = "[Service]\nUser=ben\nGroup=zgibtsnicht\nExecStart=/opt/z/bin/z\n";
    ( $o, $ok ) = sh('systemctl start z');
    ok( !$ok && sh('journalctl -u z') =~ /Failed to determine group credentials/, 'Group= unbekannt: 216/GROUP' );
    dev()->{files}{'/etc/systemd/system/w.service'} = "[Service]\nUser=www-data\nExecStart=/opt/w/bin/w\n";
    ( $o, $ok ) = sh('systemctl start w');
    ok( $ok, 'Grundkonto www-data muss der Fall nicht nennen' ) or diag $o;
}

# --- oneshot mit Skript ----------------------------------------------------------------
{
    fresh();
    delete dev()->{oneshot_scripts};
    sh('systemctl start aufraeumen.service');
    is( sh('ls /srv/daten'), "a.csv\nb.csv\nc.csv", 'ohne oneshot_scripts: das Skript laeuft nicht (wie bisher)' );
    fresh();
    my ( $o, $ok ) = sh('systemctl start aufraeumen.service; ls /srv/daten');
    is( $o, 'b.csv', 'oneshot-Dienst mit Shell-Skript: das Skript laeuft beim Start' );
    is( dev()->{services}{aufraeumen}{runs}, 1, '... ein Lauf' );
    ok( !dev()->{services}{aufraeumen}{active}, '... danach inactive' );
    ( $o, $ok ) = sh('systemctl start kaputt.service');
    ok( !$ok, 'Skript endet mit 3: Start scheitert' );
    like( $o, qr/Job for kaputt\.service failed/, '... wie systemd' );
    ok( dev()->{services}{kaputt}{failed}, '... failed' );
    sh('chmod 644 /usr/local/bin/aufraeumen.sh');
    ( $o, $ok ) = sh('systemctl start aufraeumen.service');
    ok( !$ok, 'Skript ohne Ausfuehrrecht (direkt gestartet): Start scheitert' );
    like( sh('journalctl -u aufraeumen'), qr/Failed to execute \/usr\/local\/bin\/aufraeumen\.sh: Permission denied/, '... 203/EXEC im Journal' );
    ( $o, $ok ) = sh('systemctl start schreiber.service');
    ok( !$ok && !exists dev()->{files}{'/srv/zu/von-ben'}, 'Skript laeuft als User= der Unit (ohne Schreibrecht: scheitert)' );
    like( sh('journalctl -u schreiber'), qr{touch: cannot touch '/srv/zu/von-ben': Permission denied}, '... Meldung im Journal' );
}

done_testing;
