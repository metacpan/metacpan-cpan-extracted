#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator fuer Server-Faelle.
# Behauptet wird: Platten (df/du) rechnen aus den Dateien; eine geloeschte, noch
# offene Datei belegt weiter Platz, bis der Dienst neu startet; Rechte
# (ls -l, chmod, chown, usermod) wirken auf die Startbedingungen von Diensten;
# systemd startet nur, wenn die Bedingungen halten, und zeigt die Ursache im
# Journal; Unit-Dateien wirken erst nach daemon-reload; der Resolver folgt
# /etc/resolv.conf bzw. systemd-resolved.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = {
    srv => {
        type   => 'linux',
        mounts => { '/' => { dev => '/dev/vda1', size => '20G', used => '6G' }, '/var' => { dev => '/dev/vdb1', size => '16G', used => '1G' } },
        users  => { app => { uid => 1001, groups => ['app'] }, 'www-data' => { uid => 33, groups => ['www-data'] } },
        groups => { 'ssl-cert' => { gid => 110 } },
        files  => {
            '/var/log/app/debug.log' => { size => '14G', owner => 'app', group => 'app', mode => '0640', open_by => 'app', content => "x\n" },
            '/etc/ssl/private/app.key' => { content => "KEY\n", owner => 'root', group => 'ssl-cert', mode => '0640' },
            '/etc/systemd/system/app.service' => "[Service]\nUser=app\nExecStart=/usr/local/bin/app\n",
            '/etc/resolv.conf' => "nameserver 10.0.0.53\nsearch example.internal\n",
            '/etc/hosts'       => "127.0.0.1 localhost\n",
        },
        services => {
            app => {
                active => JSON::MaybeXS::true(), user => 'app', description => 'Beispiel-App',
                unit => '/etc/systemd/system/app.service',
                unit_loaded => "[Service]\nUser=app\nExecStart=/usr/local/bin/app\n",
                journal => ['Oct 20 09:00:00 srv systemd[1]: Started app.service - Beispiel-App.'],
                needs => [
                    { free => { mount => '/var', min => '2G' }, log => ['Oct 20 09:12:03 srv app[1234]: write /var/log/app/debug.log: no space left on device'] },
                    { can => { user => 'app', read => '/etc/ssl/private/app.key' }, log => ['Oct 20 09:12:03 srv app[1234]: open /etc/ssl/private/app.key: permission denied'] },
                    { state => [ 'services', 'app', 'unit_loaded' ], regex => 'ExecStart=/usr/local/bin/app', log => ['Oct 20 09:12:03 srv systemd[1]: app.service: Failed to locate executable'] },
                ],
            },
        },
        dns_servers => { '10.0.0.53' => { 'db.example.internal' => '10.0.0.20' }, '9.9.9.9' => { 'example.org' => '192.0.2.10' } },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'srv', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}

# --- Platte voll, offene Datei -------------------------------------------------
{
    fresh();
    like( sh('df -h /var'), qr{^/dev/vdb1\s+16G\s+15G\s+1\.0G\s+94% /var$}m, 'df -h aus Grundlast + Dateien' );
    like( sh('du -sh /var/log/*'), qr{^14G\t/var/log/app$}m, 'du mit Muster' );
    is( sh('find /var -size +1G'), '/var/log/app/debug.log', 'find -size' );
    sh('rm /var/log/app/debug.log');
    like( sh('df -h /var'), qr{ 94% /var$}m, 'geloescht, aber noch offen: Platz bleibt belegt' );
    like( sh('lsof +L1'), qr{debug\.log \(deleted\)}, 'lsof +L1 zeigt die offene, geloeschte Datei' );
    sh('systemctl restart app');
    like( sh('df -h /var'), qr{ 7% /var$}m, 'Neustart des Dienstes gibt den Platz frei' );

    fresh();
    sh(': > /var/log/app/debug.log');
    like( sh('df -h /var'), qr{ 7% /var$}m, ': > datei leert sofort' );
    is( $state->{srv}{files}{'/var/log/app/debug.log'}{owner}, 'app', '... Rechte bleiben' );
    fresh();
    sh('truncate -s 0 /var/log/app/debug.log');
    like( sh('df -h /var'), qr{ 7% /var$}m, 'truncate -s 0 ebenso' );
}

# --- Dienst startet nur, wenn die Bedingungen halten -------------------------
subtest 'Dienst startet nur, wenn die Bedingungen halten' => sub {
    my $why = need_parts('+Expectation');
    plan skip_all => $why if $why;
    fresh();
    $state->{srv}{services}{app}{active} = JSON::MaybeXS::false();
    my ( $o, $ok ) = sh('systemctl restart app');
    ok( !$ok, 'Platte voll: Start scheitert' );
    like( $o, qr/Job for app\.service failed/, '... wie systemd' );
    like( sh('journalctl -u app -n 5'), qr/no space left on device/, 'Journal nennt die Ursache' );
    like( sh('systemctl status app'), qr/Active: failed \(Result: exit-code\)/, 'status: failed' );
    sh('truncate -s 0 /var/log/app/debug.log');
    ( $o, $ok ) = sh('systemctl restart app');
    ok( !$ok, 'danach scheitert die naechste Bedingung (Rechte)' );
    like( sh('journalctl -u app'), qr/permission denied/, '... Journal nennt sie' );
    like( sh('ls -l /etc/ssl/private/app.key'), qr/^-rw-r----- 1 root\s+ssl-cert/, 'ls -l' );
    is( ( sh('usermod -aG ssl-cert app') )[1], 1, 'usermod -aG' );
    like( sh('id app'), qr/ssl-cert/, '... id zeigt die Gruppe' );
    ( $o, $ok ) = sh('systemctl restart app');
    ok( $ok, 'jetzt startet der Dienst' );
    is( sh('systemctl is-active app'), 'active', 'is-active' );

    fresh();
    sh('chmod o+r /etc/ssl/private/app.key');
    is( $state->{srv}{files}{'/etc/ssl/private/app.key'}{mode}, '0644', 'chmod symbolisch' );
    sh('chmod 600 /etc/ssl/private/app.key && chown app /etc/ssl/private/app.key');
    is_deeply( [ @{ $state->{srv}{files}{'/etc/ssl/private/app.key'} }{qw( mode owner )} ], [ '0600', 'app' ], 'chmod oktal, chown' );
    ( $o, $ok ) = sh('chown nobody2 /etc/ssl/private/app.key');
    is( $o, "chown: invalid user: 'nobody2'", 'unbekannter Benutzer' );
};

# --- Unit-Datei und daemon-reload --------------------------------------------
subtest 'Unit-Datei und daemon-reload' => sub {
    my $why = need_parts('+Expectation');
    plan skip_all => $why if $why;
    fresh();
    $state->{srv}{services}{app}{unit_loaded} = "[Service]\nExecStart=/usr/local/bin/ap\n";
    $state->{srv}{services}{app}{active}      = JSON::MaybeXS::false();
    $state->{srv}{files}{'/var/log/app/debug.log'}{size} = '1M';
    sh('usermod -aG ssl-cert app');
    my ( $o, $ok ) = sh('systemctl restart app');
    ok( !$ok, 'falsche Unit geladen: scheitert' );
    like( $o, qr/changed on disk\. Run 'systemctl daemon-reload'/, 'Warnung: Datei weicht ab' );
    sh('systemctl daemon-reload');
    ( $o, $ok ) = sh('systemctl restart app');
    ok( $ok, 'nach daemon-reload startet der Dienst' );
    sh('systemctl disable app');
    is( sh('systemctl is-enabled app'), 'disabled', 'disable' );
};

# --- Resolver ----------------------------------------------------------------
{
    fresh();
    is( sh('getent hosts db'), '10.0.0.20       db', 'getent ueber resolv.conf mit search' );
    my ( $o, $ok ) = sh('getent hosts example.org');
    ok( !$ok, 'interner Server kennt den Namen nicht' );
    sh(q{printf 'nameserver 9.9.9.9\n' > /etc/resolv.conf});
    like( sh('getent hosts example.org'), qr/^192\.0\.2\.10/, 'resolv.conf geaendert: anderer Server' );

    fresh();
    $state->{srv}{files}{'/etc/resolv.conf'} = { link => '../run/systemd/resolve/stub-resolv.conf' };
    $state->{srv}{resolved} = { global => { dns => [] }, links => { eth0 => { dns => ['9.9.9.9'], domains => [] } } };
    like( sh('cat /etc/resolv.conf'), qr/\Anameserver 127\.0\.0\.53/, 'Stub von systemd-resolved' );
    ( $o, $ok ) = sh('getent hosts db.example.internal');
    ok( !$ok, 'falscher DNS am Link' );
    sh('resolvectl dns eth0 10.0.0.53');
    like( sh('resolvectl status eth0'), qr/DNS Servers: 10\.0\.0\.53/, 'resolvectl dns setzt den Link' );
    like( sh('getent hosts db.example.internal'), qr/^10\.0\.0\.20/, '... und der Name loest auf' );
}

# --- Anwendungsdienste ----------------------------------------
# Behauptet: ein Dienst mit reload_config liest seine Datei auch beim reload
# (gunicorn/prometheus: SIGHUP), ohne Neustart zu zaehlen; ohne die Angabe nur
# beim Neustart. Programme mit Pfad laufen, wenn es die Datei gibt (Luecke der
# Simulation), sonst antwortet bash wie echt; python3/node/perl sind installiert.
{
    fresh();
    $state->{srv}{files}{'/etc/app/gunicorn.conf.py'} = "timeout = 30\n";
    $state->{srv}{files}{'/opt/app/venv/bin/gunicorn'} = { content => "#!python\n", mode => '0755' };
    $state->{srv}{services}{web} = { active => JSON::MaybeXS::true(), config => '/etc/app/gunicorn.conf.py', running => "timeout = 30\n" };
    sh(q{sed -i 's/timeout = 30/timeout = 120/' /etc/app/gunicorn.conf.py});
    sh('systemctl reload web');
    is( $state->{srv}{services}{web}{running}, "timeout = 30\n", 'ohne reload_config: reload liest die Datei nicht' );
    $state->{srv}{services}{web}{reload_config} = JSON::MaybeXS::true();
    sh('systemctl reload web');
    is( $state->{srv}{services}{web}{running}, "timeout = 120\n", 'mit reload_config: reload liest die Datei' );
    ok( !$state->{srv}{services}{web}{restarts}, '... und zaehlt keinen Neustart' );
    $state->{srv}{files}{'/etc/app/gunicorn.conf.py'} = "timeout = 90\n";
    ok( ( sh('systemctl kill -s HUP web') )[1], 'systemctl kill -s HUP' );
    is( $state->{srv}{services}{web}{running}, "timeout = 90\n", '... wirkt wie reload' );
    my ( undef, undef, $kgap ) = sh('systemctl kill -s USR1 web');
    ok( $kgap, 'anderes Signal (USR1): Luecke der Simulation' );

    $state->{srv}{files}{'/etc/systemd/system/web.service'} = "[Service]\nExecStart=/opt/app/venv/bin/gunicorn\n";
    $state->{srv}{services}{web}{unit} = '/etc/systemd/system/web.service';
    my ( $ro, $rok ) = sh('systemctl reload web');
    ok( !$rok && $ro =~ /Job type reload is not applicable/, 'Unit ohne ExecReload: reload scheitert wie bei systemd' );
    sh(q{sed -i 's/timeout = 90/bind = "unix:\/run\/app.sock"/' /etc/app/gunicorn.conf.py});
    is( $state->{srv}{files}{'/etc/app/gunicorn.conf.py'}, qq{bind = "unix:/run/app.sock"\n}, 'sed: entwerteter Trenner im Ersatz' );
    my ( $o, $ok, $gap ) = sh('/opt/app/venv/bin/gunicorn --check-config');
    ok( !$ok && $gap, 'Programm mit Pfad: Luecke der Simulation' );
    ( $o, $ok, $gap ) = sh('/opt/app/.venv/bin/gunicorn --version');
    is( $o, 'bash: /opt/app/.venv/bin/gunicorn: No such file or directory', 'fehlender Pfad wie bash' );
    ok( !$gap, '... keine Luecke' );
    ( $o, $ok, $gap ) = sh('python3 -c "import app"');
    ok( $gap && $o !~ /command not found/, 'python3 ist installiert (Luecke statt command not found)' );
}

# --- Journal nach Start/Neustart, find -type d ---------------
# Behauptet: ein Neustart erscheint im Journal (systemd-Zeilen und die
# Startmeldungen start_log, als Kolon ueber den Zustand), unter _log; find
# listet auch Verzeichnisse, die sich nur aus Dateipfaden ergeben.
subtest 'Journal nach Start/Neustart, find -type d' => sub {
    my $why = need_parts('+Template');
    plan skip_all => $why if $why;
    fresh();
    $state->{srv}{clock} = 'Oct 24 09:30';
    $state->{srv}{files}{'/etc/app/env'} = "PORT=3000\n";
    $state->{srv}{services}{web} = { active => JSON::MaybeXS::true(), description => 'Web', exec => 'node', config => '/etc/app/env',
        running => "PORT=3001\n", journal => ['Oct 24 07:30:13 srv node[51022]: listening on 3001'],
        start_log => [q{listening on <: re($state["srv"].services.web.running, "PORT=3000") ? 3000 : 3001 :>}] };
    sh('systemctl restart web');
    my $j = sh('journalctl -u web -n 4');
    like( $j, qr/^Oct 24 09:30:\d\d srv systemd\[1\]: Started web\.service - Web\.$/m, 'Neustart im Journal' );
    like( $j, qr/node\[\d+\]: listening on 3000$/m, '... mit der Startmeldung aus dem neuen Zustand' );
    ok( $state->{srv}{services}{web}{_log}, '... unter _log' );
    sh('systemctl stop web');
    like( sh('journalctl -u web -n 1'), qr/Stopped web\.service/, 'Stopp im Journal' );
    $state->{srv}{files}{'/etc/systemd/system/web.service'} = "[Service]\nUser=app\nRuntimeDirectory=web\nExecStart=/usr/bin/node app.js\n";
    $state->{srv}{services}{web}{unit} = '/etc/systemd/system/web.service';
    sh('systemctl start web');
    is( $state->{srv}{dirs}{'/run/web'}{owner}, 'app', 'RuntimeDirectory legt /run/web fuer den Dienstbenutzer an' );
    sh('systemctl stop web');
    $state->{srv}{services}{web}{runtime_files} = [ { path => '/run/web/web.sock', type => 'socket' } ];
    sh('systemctl start web');
    like( sh('ls -l /run/web'), qr/^srw-rw---- 1 app\s+app\s+0 .* web\.sock$/m, 'runtime_files: Socket des laufenden Dienstes' );

    fresh();
    $state->{srv}{files}{'/srv/a/b/c.txt'} = "x\n";
    is( sh('find /srv -type d'), "/srv\n/srv/a\n/srv/a/b", 'find -type d: Verzeichnisse aus Dateipfaden' );
    is( sh('find /srv -maxdepth 1'), "/srv\n/srv/a", 'find -maxdepth' );
    is( sh('find /srv -type f'), '/srv/a/b/c.txt', 'find -type f' );
    delete $state->{srv}{mounts};
    like( sh('df -h /srv'), qr{^/dev/vda1\s+40G\s+\S+\s+\S+\s+\d+% /$}m, 'ohne mounts: Wurzeldateisystem' );
    like( sh('mount'), qr{^/dev/vda1 on / type ext4 \(rw,relatime\)$}m, 'mount listet es' );
    is( sh(q{find /srv -type d -exec stat -c '%U %n' {} \;}), "root /srv\nroot /srv/a\nroot /srv/a/b", 'find -exec … {} \;' );
    sh('find /srv -type f -exec chmod 600 {} +');
    is( $state->{srv}{files}{'/srv/a/b/c.txt'}{mode}, '0600', 'find -exec … {} +' );
    $state->{srv}{files}{'/srv/a/d.conf'} = "y=1\nx=2\n";
    is( sh('grep -rn x /srv'), "/srv/a/b/c.txt:1:x\n/srv/a/d.conf:2:x=2", 'grep -rn ueber ein Verzeichnis mit Dateinamen' );
    is( sh('grep -rl x /srv/'), "/srv/a/b/c.txt\n/srv/a/d.conf", 'grep -rl' );
    is( sh('grep x /srv/a/d.conf /srv/a/b/c.txt'), "/srv/a/d.conf:x=2\n/srv/a/b/c.txt:x", 'mehrere Dateien: Namen davor' );
    is( ( sh('grep x /srv') )[0], 'grep: /srv: Is a directory', 'Verzeichnis ohne -r' );
    is( sh('grep -c x /srv/a/d.conf'), '1', 'grep -c' );
    $state->{srv}{files}{'/srv/t.yml'} = "a:\n\tb: 1\n";
    is( sh('cat -A /srv/t.yml'), "a:\$\n^Ib: 1\$", 'cat -A zeigt Tabs und Zeilenenden' );
    is( sh('cat -n /srv/t.yml'), "     1\ta:\n     2\t\tb: 1", 'cat -n nummeriert' );
    $state->{srv}{files}{'/srv/f.yml'} = "for: 5m\nx\nfor: 5m\n";
    sh(q{sed -i '0,/for: 5m/s//for: 15m/' /srv/f.yml});
    is( $state->{srv}{files}{'/srv/f.yml'}, "for: 15m\nx\nfor: 5m\n", 'sed 0,/re/s//…/: nur der erste Treffer' );
    sh(q{sed -i 's/x/y/; s/for: 5m/for: 1m/;/^y$/d' /srv/f.yml});
    is( $state->{srv}{files}{'/srv/f.yml'}, "for: 15m\nfor: 1m\n", 'sed: mehrere Befehle mit ; getrennt' );
};

# --- Release-Verzeichnisse und Symlinks --------------------------------------
# Behauptet: Pfade durch einen Symlink (current -> releases/X) werden aufgeloest
# (cat, ls); ln -sf ohne -n auf einen Symlink zu einem Verzeichnis legt den Link
# darin an (wie GNU ln), ln -sfn bzw. mv -T ersetzen ihn; readlink [-f].
{
    fresh();
    $state->{srv}{files}{'/srv/app/releases/1/app.py'} = "eins\n";
    $state->{srv}{files}{'/srv/app/releases/2/app.py'} = "zwei\n";
    $state->{srv}{files}{'/srv/app/current'} = { link => '/srv/app/releases/2' };
    is( sh('cat /srv/app/current/app.py'), 'zwei', 'cat durch den Symlink' );
    is( ( sh('cd /srv/app/current && cat /srv/app/current/app.py') )[0], 'zwei', 'cd in ein vorhandenes Verzeichnis' );
    is( ( sh('cd /srv/nix') )[0], 'bash: cd: /srv/nix: No such file or directory', 'cd ins Leere' );
    is( ( sh('cat /srv/nix; echo $?') )[0], "cat: /srv/nix: No such file or directory\n1", '$? des vorigen Befehls' );
    is( sh('ls /srv/app/current'), 'app.py', 'ls folgt dem Symlink' );
    like( sh('ls -l /srv/app'), qr{current -> /srv/app/releases/2$}m, 'ls -l zeigt den Link' );
    is( sh('readlink /srv/app/current'), '/srv/app/releases/2', 'readlink' );

    sh('ln -sf /srv/app/releases/1 /srv/app/current');
    is( $state->{srv}{files}{'/srv/app/current'}{link}, '/srv/app/releases/2', 'ln -sf ohne -n: current unveraendert' );
    is( $state->{srv}{files}{'/srv/app/releases/2/1'}{link}, '/srv/app/releases/1', '... Link landet im Ziel' );

    fresh();
    $state->{srv}{files}{'/srv/app/releases/1/app.py'} = "eins\n";
    $state->{srv}{files}{'/srv/app/releases/2/app.py'} = "zwei\n";
    $state->{srv}{files}{'/srv/app/current'} = { link => 'releases/2' };
    is( sh('readlink -f /srv/app/current'), '/srv/app/releases/2', 'readlink -f, relativer Link' );
    ok( ( sh('ln -sfn releases/1 /srv/app/current') )[1], 'ln -sfn' );
    is( sh('cat /srv/app/current/app.py'), 'eins', '... ersetzt den Link' );
    my ( $o, $ok ) = sh('ln -s /srv/app/releases/2 /srv/app/current.neu && mv -T /srv/app/current.neu /srv/app/current');
    ok( $ok, 'ln -s + mv -T' );
    is( $state->{srv}{files}{'/srv/app/current'}{link}, '/srv/app/releases/2', '... ersetzt den Link' );
    ( $o, $ok ) = sh('ln -s /srv/app/releases/1/app.py /srv/app/x && ln -s /srv/app/releases/2/app.py /srv/app/x');
    ok( !$ok, 'ln -s auf einen vorhandenen Link zu einer Datei ohne -f scheitert' );
}

# --- diff und cmp -----------------------------------------------------------
# Behauptet: diff vergleicht zeilenweise (Normalformat und -u), gleich heisst
# leer und Erfolg, verschieden Exit 1; cmp nennt das erste abweichende Byte.
{
    fresh();
    $state->{srv}{files}{'/etc/a.conf'} = "eins\nzwei\ndrei\nvier\n";
    $state->{srv}{files}{'/etc/b.conf'} = "eins\nZWEI\ndrei\nvier\nfuenf\n";
    $state->{srv}{files}{'/etc/c.conf'} = "eins\nzwei\ndrei\nvier\n";
    my ( $o, $ok ) = sh('diff /etc/a.conf /etc/b.conf');
    is( $o, "2c2\n< zwei\n---\n> ZWEI\n4a5\n> fuenf", 'diff Normalformat' );
    ok( !$ok, 'diff: verschieden ist Exit 1' );
    ( $o, $ok ) = sh('diff /etc/a.conf /etc/c.conf');
    is( $o, '', 'diff: gleich ist leer' );
    ok( $ok, 'diff: gleich ist Erfolg' );
    is( sh('diff -u /etc/a.conf /etc/b.conf'),
        "--- /etc/a.conf\n+++ /etc/b.conf\n\@\@ -1,4 +1,5 \@\@\n eins\n-zwei\n+ZWEI\n drei\n vier\n+fuenf", 'diff -u' );
    is( ( sh('diff /etc/a.conf /etc/nix') )[0], 'diff: /etc/nix: No such file or directory', 'diff ohne Datei' );
    is( ( sh('cmp /etc/a.conf /etc/b.conf') )[0], '/etc/a.conf /etc/b.conf differ: byte 6, line 2', 'cmp' );
    is( sh('for f in /etc/a.conf /etc/b.conf; do head -n 1 $f; echo "-- ${f}"; done; echo fertig'), "eins\n-- /etc/a.conf\neins\n-- /etc/b.conf\nfertig", 'for-Schleife' );
    $state->{srv}{files}{'/opt/r/1/app.conf'}     = "port 1\n";
    $state->{srv}{files}{'/opt/r/1/lib/A.pm'}     = "a\n";
    $state->{srv}{files}{'/opt/r/2/app.conf'}     = "port 2\n";
    $state->{srv}{files}{'/opt/r/2/lib/A.pm'}     = "a\n";
    $state->{srv}{files}{'/opt/r/2/lib/B.pm'}     = "b\n";
    is( sh('diff -r /opt/r/1/ /opt/r/2/'), "diff -r /opt/r/1/app.conf /opt/r/2/app.conf\n1c1\n< port 1\n---\n> port 2\nOnly in /opt/r/2/lib: B.pm", 'diff -r ueber Verzeichnisse' );
    is( sh('diff /opt/r/1 /opt/r/2'), "diff -r /opt/r/1/app.conf /opt/r/2/app.conf\n1c1\n< port 1\n---\n> port 2", 'diff ohne -r: nur die oberste Ebene' );
    is( sh('which mysqld ls redis-cli'), "/usr/bin/ls", 'which: ohne Datenbank kein mysqld/redis-cli' );
    ok( !( sh('which tcpdump') )[1], 'which: nicht installiert ist Exit 1' );
}

# --- ssh zu einem anderen Geraet ---------------------------------------------
# Behauptet: ssh <name|adresse> befehl laeuft auf dem anderen Geraet; andere Ziele sind
# eine Luecke der Simulation.
{
    fresh();
    $state->{db9} = { type => 'linux', interfaces => { eth0 => { addr => ['10.20.0.33/24'], state => 'UP' } },
        files => { '/etc/hostname' => "db9\n" } };
    is( sh('ssh 10.20.0.33 cat /etc/hostname'), 'db9', 'ssh per Adresse' );
    is( sh(q{ssh root@db9 'cat /etc/hostname | wc -l'}), '1', 'ssh per Name mit Pipeline drueben' );
    like( ( sh('ssh 10.20.0.99 true') )[2], qr/ssh 10\.20\.0\.99/, 'ssh zu einem nicht nachgebildeten Geraet: Luecke' );
}

# --- Drop-ins ----------------------------------------------------------------
# Behauptet: <unit>.service.d/*.conf gehoeren zur Unit (cat, status, show); mit
# unit_loaded wirken sie erst nach daemon-reload, und der Prozess laeuft mit dem,
# was beim letzten Start geladen war (_started); zwei ExecStart= ohne leere
# Zuweisung sind bad-setting (Start verweigert), ein Link auf /dev/null schaltet
# einen Drop-in ab.
{
    fresh();
    $state->{srv}{files}{'/lib/systemd/system/api.service'} = "[Unit]\nDescription=API\n\n[Service]\nUser=api\nExecStart=/usr/bin/node /opt/api/server.js\nExecReload=/bin/kill -HUP \$MAINPID\n";
    $state->{srv}{services}{api} = { active => JSON::MaybeXS::true(), exec => 'node', user => 'api', unit => '/lib/systemd/system/api.service', unit_loaded => 'current' };
    prepare($state);
    my $A = $state->{srv}{services}{api};
    is( $A->{_started}{ExecStart}[0], '/usr/bin/node /opt/api/server.js', 'prepare: laufende Fassung' );
    is( sh('systemctl show api -p LimitNOFILE --value'), '524288', 'show: Vorgabe von Debian 12' );
    sh(q{mkdir -p /etc/systemd/system/api.service.d && printf '[Service]\nLimitNOFILE=65536\nEnvironment="NODE_ENV=production" PORT=3000\n' > /etc/systemd/system/api.service.d/limits.conf});
    like( sh('systemctl cat api'), qr{# /etc/systemd/system/api.service.d/limits.conf\n\[Service\]\nLimitNOFILE=65536}, 'cat zeigt den Drop-in' );
    like( sh('systemctl status api'), qr{Drop-In: /etc/systemd/system/api.service.d\n\s+└─limits.conf}, 'status nennt den Drop-in' );
    like( sh('systemctl restart api'), qr/daemon-reload/, 'restart ohne daemon-reload: Warnung' );
    ok( !$A->{_started}{LimitNOFILE}, '... und die alte Fassung laeuft' );
    is( sh('systemctl show api -p NeedDaemonReload'), 'NeedDaemonReload=yes', 'show: NeedDaemonReload' );
    sh('systemctl daemon-reload && systemctl restart api');
    is( $A->{_started}{LimitNOFILE}, '65536', 'nach daemon-reload und restart: neues Limit' );
    is_deeply( $A->{_started}{Environment}, { NODE_ENV => 'production', PORT => 3000 }, 'Environment als Hash' );
    is( sh('systemctl show api -p LimitNOFILE,LimitNOFILESoft'), "LimitNOFILE=65536\nLimitNOFILESoft=65536", 'show mehrere' );
    my $pid = sh('systemctl show api -p MainPID --value');
    like( sh("cat /proc/$pid/limits"), qr/^Max open files\s+65536\s+65536\s+files/m, '/proc/<pid>/limits aus der laufenden Fassung' );
    like( sh('systemctl status api'), qr/Main PID: $pid \(node\)/, 'status: dieselbe PID' );

    sh(q{printf '[Service]\nExecStart=/usr/bin/node /opt/api/server.js --workers 4\n' > /etc/systemd/system/api.service.d/override.conf});
    sh('systemctl daemon-reload');
    my ( $o, $ok ) = sh('systemctl restart api');
    ok( !$ok, 'zwei ExecStart: Start verweigert' );
    like( $o, qr/bad unit file setting/, '... mit Meldung' );
    ok( $A->{active}, '... der laufende Prozess laeuft weiter' );
    is( $A->{_started}{LimitNOFILE}, '65536', '... mit seiner alten Fassung' );
    like( sh('journalctl -u api'), qr/more than one ExecStart= setting/, '... im Journal' );
    like( sh('systemctl status api'), qr/Loaded: bad-setting/, '... status bad-setting' );
    sh(q{printf '[Service]\nExecStart=\nExecStart=/usr/bin/node /opt/api/server.js --workers 4\n' > /etc/systemd/system/api.service.d/override.conf});
    sh(q{printf '[Service]\nExecStart=\n' > /etc/systemd/system/api.service.d/override.conf});
    sh('systemctl daemon-reload');
    like( sh('systemctl restart api; journalctl -u api -n 3'), qr/has no ExecStart=/, 'nur geleert: kein ExecStart' );
    sh(q{printf '[Service]\nExecStart=\nExecStart=/usr/bin/node /opt/api/server.js --workers 4\n' > /etc/systemd/system/api.service.d/override.conf});
    ok( ( sh('systemctl daemon-reload && systemctl restart api') )[1], 'leere Zuweisung davor: startet' );
    is_deeply( $A->{_started}{ExecStart}, ['/usr/bin/node /opt/api/server.js --workers 4'], '... mit der neuen Befehlszeile' );
    sh(q{printf 'LimitNOFILE=4096\n' > /etc/systemd/system/api.service.d/ohne-abschnitt.conf});
    sh('systemctl daemon-reload && systemctl restart api');
    is( $A->{_started}{LimitNOFILE}, '65536', 'Drop-in ohne Abschnitt: wirkt nicht' );
    sh('rm /etc/systemd/system/api.service.d/ohne-abschnitt.conf');
    sh('ln -s /dev/null /etc/systemd/system/api.service.d/limits.conf');
    $state->{srv}{files}{'/etc/systemd/system/api.service.d/limits.conf'} = { link => '/dev/null' };
    sh('systemctl daemon-reload && systemctl restart api');
    ok( !$A->{_started}{LimitNOFILE}, 'Drop-in auf /dev/null: abgeschaltet' );
    sh(q{printf '[Service]\nLimitNOFILE=2048\n' > /etc/systemd/system/api.service.d/neu.conf});
    sh('systemctl daemon-reload && systemctl reload-or-restart api');
    ok( !$A->{_started}{LimitNOFILE}, 'reload-or-restart mit ExecReload: nur reload, kein neuer Prozess' );
}

# --- nginx ------------------------------------------------------------------
# Behauptet: nginx -t prueft Klammern und Semikolons der Konfiguration (auch mit
# Umleitung), -s reload wirkt wie systemctl reload; ohne nginx-Dienst nicht installiert.
{
    fresh();
    like( ( sh('nginx -t') )[0], qr/command not found/, 'ohne Dienst nicht installiert' );
    $state->{srv}{services}{nginx} = { active => JSON::MaybeXS::true(), exec => 'nginx' };
    $state->{srv}{files}{'/etc/nginx/nginx.conf'} = "events {}\nhttp {\n  include /etc/nginx/sites-enabled/*;\n}\n";
    $state->{srv}{files}{'/etc/nginx/sites-enabled/app'} = "server {\n  listen 80;\n  location / { proxy_pass http://127.0.0.1:8000; }\n}\n";
    my ( $o, $ok ) = sh('nginx -t 2>&1');
    ok( $ok, 'nginx -t mit Umleitung' );
    like( $o, qr/test is successful/, '... erfolgreich' );
    $state->{srv}{files}{'/etc/nginx/sites-enabled/app'} = "server {\n  listen 80\n  location / { proxy_pass http://127.0.0.1:8000; }\n}\n";
    like( ( sh('nginx -t') )[0], qr{directive "listen" is not terminated by ";" in /etc/nginx/sites-enabled/app:2}, 'fehlendes Semikolon' );
    $state->{srv}{files}{'/etc/nginx/sites-enabled/app'} = "server {\n  listen 80;\n";
    like( ( sh('nginx -t') )[0], qr/unexpected end of file/, 'offene Klammer' );
    sh('nginx -s reload');
    like( sh('journalctl -u nginx'), qr/Reloaded nginx/, 'nginx -s reload' );
}

# --- Prozesse ------------------------------------------------------------------
# Behauptet: ps zeigt die Befehlszeile der laufenden Fassung (ExecStart aus _started),
# gunicorn mit seinen Workern als Kinder des Masters; -ef, -eo, --ppid, -C wie procps;
# /proc/<pid>/cmdline mit NUL getrennt.
{
    fresh();
    $state->{srv}{files}{'/etc/b/g.conf.py'} = "workers = 3\n";
    $state->{srv}{services}{b} = { active => JSON::MaybeXS::true(), exec => 'gunicorn', user => 'b',
        _started => { ExecStart => ['/opt/b/venv/bin/gunicorn --config /etc/b/g.conf.py --workers 6 b.wsgi:app'] } };
    $state->{srv}{services}{c} = { active => JSON::MaybeXS::true(), exec => 'gunicorn', user => 'c',
        _started => { ExecStart => ['/opt/c/venv/bin/gunicorn --config /etc/b/g.conf.py c.wsgi:app'] } };
    my $master = sh('systemctl show b -p MainPID --value');
    is( scalar( () = sh("ps --ppid $master -o pid=") =~ /\d+/g ), 6, 'sechs Worker unter dem Master' );
    like( sh('ps -ef | grep "[g]unicorn" | head -1'), qr{\Ab\s+\d+\s+1\s.*/opt/b/venv/bin/gunicorn --config /etc/b/g\.conf\.py --workers 6 b\.wsgi:app\z}, 'ps -ef mit Befehlszeile' );
    my $cm = sh('systemctl show c -p MainPID --value');
    is( scalar( () = sh("ps --ppid $cm -o pid=") =~ /\d+/g ), 3, 'Worker aus der --config-Datei' );
    like( sh("cat /proc/$master/cmdline"), qr{--workers\x006\x00}, '/proc/<pid>/cmdline, NUL-getrennt' );
    like( sh('ps -eo pid,ppid,comm'), qr/\A\s*PID\s+PPID COMMAND/, 'ps -eo mit Kopf' );
    is( ( sh('ps -C gunicorn -o pid=') =~ tr/\n// ) + 1, 11, 'ps -C: Master und Worker beider Dienste' );
}

# --- Signale und Restart= --------------------------------------
# Behauptet: kill und systemctl kill halten sich an Restart= der Unit wie systemd —
# on-failure startet nach SIGKILL neu (neue PID, NRestarts), nicht nach SIGTERM;
# always auch nach SIGTERM; ohne Restart= bleibt der Dienst stehen (KILL: failed).
{
    fresh();
    for my $n (qw( a b c )) {
        my $r = { a => "Restart=on-failure\n", b => "Restart=always\n", c => '' }->{$n};
        $state->{srv}{files}{"/etc/systemd/system/$n.service"} = "[Service]\nExecStart=/usr/bin/sleep infinity\n$r\n[Install]\nWantedBy=multi-user.target\n";
        $state->{srv}{services}{$n} = { active => JSON::MaybeXS::true(), unit => "/etc/systemd/system/$n.service" };
    }
    my $pid = sh('systemctl show -p MainPID --value a');
    sh("kill -9 $pid");
    is( sh('systemctl is-active a'), 'active', 'on-failure: nach SIGKILL wieder aktiv' );
    is( sh('systemctl show -p NRestarts --value a'), '1', '... NRestarts zaehlt' );
    isnt( sh('systemctl show -p MainPID --value a'), $pid, '... mit neuer PID' );
    sh('systemctl kill a');
    is( sh('systemctl is-active a'), 'inactive', 'on-failure: SIGTERM (systemctl kill) beendet ihn' );
    sh('systemctl kill --signal=SIGTERM b');
    is( sh('systemctl is-active b'), 'active', 'always: auch nach SIGTERM wieder aktiv' );
    sh('systemctl kill -s KILL c');
    is( sh('systemctl is-active c'), 'failed', 'ohne Restart=: SIGKILL laesst ihn auf failed' );
    my ( undef, undef, $gap ) = sh('systemctl kill c');
    ok( $gap, 'systemctl kill auf einen stehenden Dienst: Luecke' );
}

done_testing;
