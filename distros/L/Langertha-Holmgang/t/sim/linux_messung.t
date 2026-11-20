#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: Befunde aus der ersten Probemessung
# (Transkripte). Behauptet wird, dass der Simulator hier antwortet wie Debian 12:
# ein Neustart vergibt eine neue Haupt-PID und eine neue Startzeit (systemctl show,
# status, ps), ein reload nicht; die Filter melden eine fehlende Datei wie GNU
# coreutils statt als Luecke; ls /usr/bin zeigt die Programme, die which kennt;
# /dev/tcp ist keine Datei (neutrale Luecke statt "No such file or directory").

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $start = {
    srv => {
        type     => 'linux',
        files    => { '/etc/app/app.conf' => "a=1\n" },
        services => {
            app   => { active => $T, description => 'App', exec => 'app', reload => $T },
            ssh   => { active => $T, description => 'OpenBSD Secure Shell server', exec => 'sshd' },
            spaet => { active => $T, description => 'Spaet', exec => 'spaet', since => 'Thu 2026-10-29 06:10:12 CET' },
        },
    },
    neu => {
        type     => 'linux',
        clock    => 'Oct 29 09:12',
        tz       => '+01:00',
        services => { web => { active => $T, description => 'Web', exec => 'web', since => 'Thu 2026-10-29 06:10:12 CET',
            journal => ['Oct 29 06:10:12 neu systemd[1]: Started web.service - Web.'] } },
    },
};
my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ( $cmd, $host ) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, $host // 'srv', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
sub prop { my ( $u, $p, $host ) = @_; return scalar sh( "systemctl show $u -p $p --value", $host ) }

subtest 'Neustart: neue Haupt-PID und Startzeit, reload nicht' => sub {
    fresh();
    my $ssh0 = prop( 'ssh', 'MainPID' );
    my $pid0 = prop( 'app', 'MainPID' );
    like( $pid0, qr/\A[1-9]\d*\z/, 'MainPID vorher' );
    is( prop( 'app', 'ExecMainStartTimestamp' ), 'Tue 2026-10-20 09:00:00 CEST', 'Startzeit vorher (Vorgabe)' );
    is( prop( 'app', 'ActiveEnterTimestamp' ), 'Tue 2026-10-20 09:00:00 CEST', 'ActiveEnterTimestamp vorher' );
    is( prop( 'app', 'NRestarts' ), '0', 'NRestarts' );
    sh('systemctl reload app');
    is( prop( 'app', 'MainPID' ), $pid0, 'reload: dieselbe PID' );
    is( prop( 'app', 'ExecMainStartTimestamp' ), 'Tue 2026-10-20 09:00:00 CEST', 'reload: dieselbe Startzeit' );
    sh('systemctl restart app');
    my $pid1 = prop( 'app', 'MainPID' );
    isnt( $pid1, $pid0, 'restart: neue PID' );
    my $ts1 = prop( 'app', 'ExecMainStartTimestamp' );
    like( $ts1, qr/\ATue 2026-10-20 09:12:\d\d CEST\z/, 'restart: Startzeit von der Uhr des Simulators' );
    is( prop( 'app', 'ActiveEnterTimestamp' ), $ts1, 'ActiveEnterTimestamp = Startzeit' );
    is( prop( 'app', 'NRestarts' ), '0', 'NRestarts zaehlt nur automatische Neustarts (wie systemd)' );
    my ($jt) = sh('journalctl -u app -n 1') =~ /\AOct 20 (09:12:\d\d) .*Started app\.service/;
    ok( defined $jt && $ts1 =~ /\Q$jt\E/, 'Startzeit = Zeit der Journalzeile "Started"' );
    like( sh('systemctl status app'), qr/Active: active \(running\) since \Q$ts1\E; 4h 4\dmin ago/, 'status: since aus dem Neustart' );
    like( sh('systemctl status app'), qr/Main PID: \Q$pid1\E \(app\)/, 'status: neue PID' );
    my $ps = sh('ps -o pid,lstart,cmd -C app');
    like( $ps, qr/^\s*\Q$pid1\E Tue Oct 20 09:12:\d\d 2026 app$/m, 'ps: neue PID und Startzeit' );
    sh('systemctl stop app; systemctl start app');
    my $pid2 = prop( 'app', 'MainPID' );
    ok( $pid2 != $pid1 && $pid2 != $pid0, 'stop + start: wieder neue PID' );
    isnt( prop( 'app', 'ExecMainStartTimestamp' ), '', 'stop + start: Startzeit gesetzt' );
    is( prop( 'ssh', 'MainPID' ), $ssh0, 'andere Dienste behalten ihre PID' );
    sh('systemctl stop app');
    is( prop( 'app', 'MainPID' ), '0', 'gestoppt: MainPID=0' );
};

subtest 'Startzeit aus dem Zustand und der Uhr des Geraets' => sub {
    my $why = need_parts('Monitoring');
    plan skip_all => $why if $why;
    fresh();
    is( prop( 'spaet', 'ExecMainStartTimestamp' ), 'Thu 2026-10-29 06:10:12 CET', 'since aus dem Zustand' );
    like( sh('systemctl status spaet'), qr/Active: active \(running\) since Thu 2026-10-29 06:10:12 CET;/, 'status: since aus dem Zustand' );
    like( sh('ps -o pid,lstart,cmd -C spaet'), qr/Thu Oct 29 06:10:12 2026 spaet/, 'ps lstart aus dem Zustand' );
    like( sh( 'systemctl status web', 'neu' ), qr/since Thu 2026-10-29 06:10:12 CET; 3h 1min ago/, 'ago von der Uhr des Geraets' );
    sh( 'systemctl restart web', 'neu' );
    like( prop( 'web', 'ExecMainStartTimestamp', 'neu' ), qr/\AThu 2026-10-29 09:12:\d\d CET\z/, 'Neustart: Uhr des Geraets' );
};

subtest 'Journal: Zeitangaben an der Uhr des Geraets' => sub {
    my $why = need_parts('Monitoring');
    plan skip_all => $why if $why;
    fresh();
    like( sh( 'journalctl --list-boots', 'neu' ), qr/Thu 2026-10-29 06:10:12 CET\x{2014}Thu 2026-10-29 09:12:00 CET\z/, '--list-boots endet jetzt' );
    my $j = sub { scalar sh( "journalctl -u web --since $_[0]", 'neu' ) };
    like( $j->('today'), qr/Started web/, '--since today' );
    like( $j->('06:00'), qr/Started web/, '--since 06:00 (heute)' );
    is( $j->('07:00'), '-- No entries --', '--since 07:00' );
    is( $j->(q{'1 hour ago'}), '-- No entries --', '--since "1 hour ago"' );
    like( $j->(q{'4 hours ago'}), qr/Started web/, '--since "4 hours ago"' );
    is( $j->('yesterday') =~ tr/\n//, 0, '--since yesterday: eine Zeile' );
    my ( $o, $ok ) = sh( 'journalctl -b -1 -u web', 'neu' );
    is( $o, 'Data from the specified boot (-1) is not available: No such boot ID in journal.', '-b -1: es gibt nur den laufenden Start' );
    ok( !$ok, '-b -1: Fehlstatus' );
    like( scalar sh( 'journalctl -b 0 -u web', 'neu' ), qr/Started web/, '-b 0: der laufende Start' );
};

subtest 'Filter: fehlende Datei wie coreutils, keine Luecke' => sub {
    fresh();
    my %want = (
        'wc -l /nope'               => q{wc: /nope: No such file or directory},
        'wc /nope'                  => q{wc: /nope: No such file or directory},
        'head -n 3 /nope'           => q{head: cannot open '/nope' for reading: No such file or directory},
        'tail -n 3 /var/log/nope'   => q{tail: cannot open '/var/log/nope' for reading: No such file or directory},
        'sort /nope'                => q{sort: cannot read: /nope: No such file or directory},
        'uniq -c /nope'             => q{uniq: /nope: No such file or directory},
        'cut -d: -f1 /nope'         => q{cut: /nope: No such file or directory},
        q{awk '{print $1}' /nope}   => q{awk: cannot open /nope (No such file or directory)},
        'wc -l nope.log'            => q{wc: nope.log: No such file or directory},
    );
    for my $c ( sort keys %want ) {
        my ( $o, $ok, $gap ) = sh($c);
        is( $o, $want{$c}, $c );
        ok( !$ok, "$c: Fehlstatus" );
        ok( !defined $gap, "$c: keine Luecke" );
    }
    my ( $o, $ok ) = sh('wc -l /etc/app/app.conf /nope');
    is( $o, "1 /etc/app/app.conf\nwc: /nope: No such file or directory\n1 total", 'wc: vorhandene gezaehlt, fehlende gemeldet' );
    ok( !$ok, 'wc mit fehlender Datei: Fehlstatus' );
    is( scalar sh('head -n 1 /etc/app/app.conf'), 'a=1', 'vorhandene Datei unveraendert' );
    is( scalar sh(q{awk -F= '/a/ {print $2}' /etc/app/app.conf}), '1', 'awk-Programm mit / ist keine Datei' );
    is( scalar sh('cat /etc/app/app.conf | head -n 1'), 'a=1', 'Pipe unveraendert' );
};

subtest 'ls /usr/bin, /bin: die Programme, die which kennt' => sub {
    fresh();
    my ( $o, $ok, $gap ) = sh('ls /usr/bin');
    ok( $ok && !defined $gap, 'ls /usr/bin antwortet' );
    my %bin = map { $_ => 1 } split /\n/, $o;
    ok( $bin{$_}, "/usr/bin/$_" ) for qw( ls grep awk sed cat systemctl journalctl python3 ps );
    ok( !$bin{$_}, "kein $_ (nicht installiert)" ) for qw( curl nc iptables );
    ok( !$bin{nft} && !$bin{cd}, 'nft liegt in /usr/sbin, cd ist eingebaut' );
    my %sbin = map { $_ => 1 } split /\n/, scalar sh('ls /usr/sbin');
    ok( $sbin{nft} && $sbin{ip} && $sbin{sshd}, '/usr/sbin: nft, ip, sshd' );
    is( scalar sh('ls /bin'), $o, '/bin wie /usr/bin (usrmerge)' );
    is( scalar sh('ls /sbin'), scalar sh('ls /usr/sbin'), '/sbin wie /usr/sbin' );
    like( scalar sh('ls -l /bin'), qr{\Alrwxrwxrwx 1 root root 7 \S+ +\d+ +\S+ /bin -> usr/bin\z}, 'ls -l /bin: Verweis' );
    like( scalar sh('ls -l /usr/bin/grep'), qr{\A-rwxr-xr-x 1 root +root +\d+ .* /usr/bin/grep\z}, 'ls -l /usr/bin/grep' );
    ( $o, $ok ) = sh('ls /usr/bin/curl');
    ok( !$ok, 'ls /usr/bin/curl: gibt es nicht' );
    for my $n (qw( ls grep awk sed cat )) {
        my $w = sh("which $n");
        ok( $bin{ $w =~ s{\A/usr/bin/}{}r }, "which $n ($w) liegt in ls /usr/bin" );
    }
    ok( ( sh('ls /usr/bin | grep -c .') ) > 50, 'eine plausible Menge' );
};

subtest '/dev/tcp: keine Datei, neutrale Luecke' => sub {
    my $why = need_parts('Sshd');
    plan skip_all => $why if $why;
    fresh();
    # (Runde 3: /dev/tcp ist jetzt eine Verbindung — offen, wo der Simulator den Lauscher
    # kennt, eine Luecke, wo nicht: srv faehrt den Dienst app mit unbekannten Ports)
    my ( $lo, $lok, $lgap ) = sh(q{timeout 2 bash -c '</dev/tcp/127.0.0.1/22'});
    ok( $lok && !defined $lgap, 'lokal auf 22 (sshd): offen' );
    for my $c ( q{bash -c 'echo > /dev/tcp/10.40.0.27/9100'}, 'echo > /dev/tcp/127.0.0.1/9100' ) {
        my ( $o, $ok, $gap ) = sh($c);
        unlike( $o // '', qr/No such file or directory/, "$c: keine falsche Meldung" );
        ok( defined $gap, "$c: als Luecke vermerkt" );
    }
    ok( !exists $state->{srv}{files}{'/dev/tcp/127.0.0.1/9100'}, 'keine Datei angelegt' );
};

# Runde 2: ein laufender Dienst lauscht sichtbar dort, wo seine
# Konfiguration es sagt (listen am Dienst, nginx aus seinen listen-Zeilen, sshd auf 22),
# und schreibt bei Start/Neustart passende Zeilen in sein Log (app_log)
my $app = {
    lb => {
        type     => 'linux',
        files    => {
            '/etc/app/app.ini'            => "[http]\nlisten = 0.0.0.0:80\n",
            '/var/log/app/app.log'        => { owner => 'app', content => "2026-10-20 06:58:02 FATAL alt\n" },
            '/etc/nginx/sites-enabled/app' => "server {\n    listen 80;\n    listen [::]:80;\n    location / { proxy_pass http://127.0.0.1:8085; }\n}\n",
        },
        services => {
            app => { active => JSON::MaybeXS::false(), failed => $T, description => 'App', exec => 'app',
                listen  => { file => '/etc/app/app.ini', regex => '(?m)^\s*listen\s*=\s*(\S+)' },
                app_log => { file => '/var/log/app/app.log', start => ['{ts} INFO  app startet, lauscht auf {listen}'],
                    fail => ['{ts} ERROR http: listen tcp {listen}: bind: permission denied', '{ts} FATAL app beendet (Exit 1)'] },
                needs => [ { state => [ 'files', '/etc/app/app.ini' ], regex => ':8085$', log => ['Oct 20 09:12:03 lb app[3120]: bind: permission denied'] } ] },
            nginx => { active => $T, description => 'nginx', exec => 'nginx' },
            ssh   => { active => $T, description => 'OpenBSD Secure Shell server', exec => 'sshd' },
        },
    },
};

subtest 'ss: Lauscher aus der Konfiguration, Log der Anwendung' => sub {
    my $why = need_parts('Sshd', '+Expectation');
    plan skip_all => $why if $why;
    $state = clone($app);
    my $ss = sh( 'ss -tlnp', 'lb' );
    like( $ss, qr/^tcp\s+LISTEN .*0\.0\.0\.0:80\s.*users:\(\("nginx",pid=\d+,fd=\d+\)\)/m, 'nginx auf 80 (listen 80)' );
    like( $ss, qr/^tcp\s+LISTEN .*\[::\]:80\s.*"nginx"/m, 'nginx auf [::]:80' );
    like( $ss, qr/^tcp\s+LISTEN .*0\.0\.0\.0:22\s.*"sshd"/m, 'sshd auf 22 (ohne sshd_config)' );
    unlike( $ss, qr/"app"/, 'app laeuft nicht: kein Lauscher' );
    my ( $o, $ok ) = sh( 'systemctl start app', 'lb' );
    ok( !$ok, 'Start scheitert (Port 80)' );
    like( sh( 'tail -n 2 /var/log/app/app.log', 'lb' ), qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d ERROR http: listen tcp 0\.0\.0\.0:80: bind: permission denied\n.* FATAL app beendet \(Exit 1\)\z/,
        'Fehlstart: Fehlerzeilen im Log' );
    sh( q{sed -i 's/0.0.0.0:80/127.0.0.1:8085/' /etc/app/app.ini}, 'lb' );
    ( $o, $ok ) = sh( 'systemctl start app', 'lb' );
    ok( $ok, 'Start gelingt' );
    my $pid = prop( 'app', 'MainPID', 'lb' );
    like( sh( 'ss -tlnp', 'lb' ), qr/^tcp\s+LISTEN .*127\.0\.0\.1:8085\s.*users:\(\("app",pid=$pid,fd=\d+\)\)/m, 'app lauscht auf 127.0.0.1:8085 mit seiner PID' );
    like( sh( 'tail -n 1 /var/log/app/app.log', 'lb' ), qr/\A2026-10-20 09:12:\d\d INFO  app startet, lauscht auf 127\.0\.0\.1:8085\z/, 'Start: Zeile im Log (Uhr)' );
    sh( q{sed -i 's/8085/8090/' /etc/app/app.ini}, 'lb' );
    like( sh( 'ss -tlnp', 'lb' ), qr/127\.0\.0\.1:8085\s/, 'Datei geaendert, ohne Neustart: lauscht weiter wie gestartet' );
    sh( 'systemctl stop app', 'lb' );
    unlike( sh( 'ss -tlnp', 'lb' ), qr/"app"/, 'gestoppt: kein Lauscher' );
    ok( !grep( { ( $_->{path}[2] // '' ) eq '/var/log/app/app.log' && !grep { /\A_/ } @{ $_->{path} } } diff( $app, $state ) ),
        'Log der Anwendung ist Laufzeitspur (keine Aenderung fuer sonst nichts geaendert)' )
        or diag explain [ diff( $app, $state ) ];
    is( scalar sh( 'wc -l /var/log/app/app.log', 'lb' ), '4 /var/log/app/app.log', 'wc zaehlt die neuen Zeilen (alt, 2 Fehler, 1 Start)' );
    sh( 'echo neu > /var/log/app/app.log', 'lb' );
    is( scalar sh( 'cat /var/log/app/app.log', 'lb' ), 'neu', 'ueberschrieben: nur der neue Inhalt' );
};

# Runde 2: nginx liefert statische Dateien nach den Rechten
# seines Arbeiters (www-data) — wget gegen die eigene Maschine zeigt 200, 403, 404
subtest 'wget: nginx liefert statische Dateien nach Rechten' => sub {
    $state = {
        web => {
            type     => 'linux',
            users    => { 'www-data' => { uid => 33, groups => ['www-data'] } },
            dirs     => { '/srv/www/shop' => { owner => 'deploy', mode => '0755' }, '/srv/www/shop/assets' => { owner => 'deploy', mode => '0700' } },
            files    => {
                '/srv/www/shop/index.html'        => { owner => 'deploy', mode => '0644', content => "<!doctype html>\n" },
                '/srv/www/shop/assets/shop.css'   => { owner => 'deploy', mode => '0600', content => "body { }\n" },
                '/etc/nginx/sites-enabled/shop'   => "server {\n    listen 80;\n    server_name shop.example.invalid;\n    root /srv/www/shop;\n    location /api/ { proxy_pass http://127.0.0.1:8085; }\n}\n",
            },
            services => { nginx => { active => $T, description => 'nginx', exec => 'nginx' } },
        },
    };
    my ( $o, $ok, $gap ) = sh( 'wget -q -O - http://127.0.0.1/index.html', 'web' );
    is( $o, '<!doctype html>', '200: Inhalt' );
    ok( $ok && !defined $gap, '200: Erfolg, keine Luecke' );
    ( $o, $ok, $gap ) = sh( q{wget -S -O /dev/null --header='Host: shop.example.invalid' http://127.0.0.1/assets/shop.css}, 'web' );
    like( $o, qr/HTTP\/1\.1 403 Forbidden/, '403: Verzeichnis 0700, Datei 0600' );
    like( $o, qr/ERROR 403: Forbidden\./, '... wie wget' );
    ok( !$ok && !defined $gap, '403: Fehlstatus, keine Luecke' );
    sh( 'chmod 755 /srv/www/shop/assets', 'web' );
    ( $o, $ok ) = sh( 'wget -q -O - http://localhost/assets/shop.css', 'web' );
    ok( !$ok, 'Verzeichnis offen, Datei 0600: weiter 403' );
    sh( 'chmod 644 /srv/www/shop/assets/shop.css', 'web' );
    ( $o, $ok ) = sh( 'wget -q -O - http://localhost/assets/shop.css', 'web' );
    is( $o, 'body { }', 'danach 200' );
    ( $o, $ok ) = sh( 'wget --spider http://127.0.0.1/', 'web' );
    like( $o, qr/Remote file exists\./, '--spider: index.html' );
    ( $o, $ok ) = sh( 'wget -q -O - http://127.0.0.1/fehlt.css', 'web' );
    ok( !$ok, '404: Datei fehlt' );
    ( $o, $ok, $gap ) = sh( 'wget -q -O - http://127.0.0.1/api/x', 'web' );
    ok( defined $gap, 'proxy_pass: Luecke' );
    ( $o, $ok ) = sh( 'wget -q -O /tmp/s.css http://127.0.0.1/assets/shop.css; cat /tmp/s.css', 'web' );
    is( $o, 'body { }', '-O DATEI schreibt' );
    sh( 'systemctl stop nginx', 'web' );
    ( $o, $ok ) = sh( 'wget -O - http://127.0.0.1/', 'web' );
    like( $o, qr/failed: Connection refused\./, 'nginx gestoppt: refused' );
};

# Runde 2: touch -d/-t/-r setzen die Zeit wie GNU (an der Uhr des
# Geraets), find -mtime/-newer, stat %y und ls --time-style lesen sie
subtest 'touch -d/-t/-r, find -mtime, stat %y, ls --time-style' => sub {
    my $why = need_parts('Monitoring');
    plan skip_all => $why if $why;
    fresh();
    my ( $o, $ok ) = sh(q{touch -d '20 days ago' /tmp/alt});
    ok( $ok, 'touch -d "20 days ago"' );
    ok( !exists $state->{srv}{files}{'/root/20 days ago'} && !exists $state->{srv}{files}{'/tmp/20 days ago'}, 'keine Datei namens "20 days ago"' );
    like( sh('ls -l /tmp/alt'), qr/ Sep 30 14:00 \/tmp\/alt\z/, 'ls -l: vor 20 Tagen' );
    is( scalar sh(q{stat -c '%y %n' /tmp/alt}), '2026-09-30 14:00:00.000000000 +0200 /tmp/alt', 'stat %y' );
    is( scalar sh('find /tmp -mtime +14'), '/tmp/alt', 'find -mtime +14 findet sie' );
    is( scalar sh('find /tmp -mtime +25'), '', 'find -mtime +25 nicht' );
    sh(q{touch -d '2026-09-30 01:30' /tmp/f});
    is( scalar sh(q{stat -c %y /tmp/f}), '2026-09-30 01:30:00.000000000 +0200', 'touch -d DATUM ZEIT' );
    like( sh('ls -l --time-style=full-iso /tmp/f'), qr/ 2026-09-30 01:30:00\.000000000 \+0200 \/tmp\/f\z/, 'ls --time-style=full-iso' );
    like( sh('ls -l --time-style=long-iso /tmp/f'), qr/ 2026-09-30 01:30 \/tmp\/f\z/, 'ls --time-style=long-iso' );
    like( sh('ls -l --full-time /tmp/f'), qr/ 2026-09-30 01:30:00\.000000000 \+0200 \/tmp\/f\z/, 'ls --full-time' );
    sh('touch -t 202610011230 /tmp/t');
    is( scalar sh(q{stat -c %y /tmp/t}), '2026-10-01 12:30:00.000000000 +0200', 'touch -t' );
    sh('touch -r /tmp/f /tmp/r');
    is( scalar sh(q{stat -c %y /tmp/r}), '2026-09-30 01:30:00.000000000 +0200', 'touch -r' );
    is( scalar sh('find /tmp -newer /tmp/f -name t'), '/tmp/t', 'find -newer' );
    sh('touch /etc/app/app.conf');
    like( sh('ls -l /etc/app/app.conf'), qr/ Oct 20 14:00 /, 'touch einer vorhandenen Datei: jetzt' );
    is( scalar sh('cat /etc/app/app.conf'), 'a=1', '... Inhalt bleibt' );
    ( $o, $ok ) = sh('touch -c /tmp/fehlt');
    ok( $ok && !exists $state->{srv}{files}{'/tmp/fehlt'}, 'touch -c legt nichts an' );
    is( scalar sh(q{date -d '20 days ago' +%F}), '2026-09-30', 'date -d "20 days ago"' );
    is( scalar sh(q{date -d yesterday '+%F %H:%M'}), '2026-10-19 14:00', 'date -d yesterday: gleiche Uhrzeit' );
    ( $o, $ok ) = sh(q{touch -d 'kein datum' /tmp/x});
    is( $o, q{touch: invalid date format 'kein datum'}, 'touch -d unlesbar: Meldung wie GNU' );
    ok( !$ok, '... Fehlstatus' );
    sh( q{touch -d '3 days ago' /tmp/n}, 'neu' );
    like( sh( 'ls -l /tmp/n', 'neu' ), qr/ Oct 26 09:12 \/tmp\/n\z/, 'Uhr des Geraets' );
    is( scalar sh( 'find /tmp -mtime +2', 'neu' ), '/tmp/n', 'find -mtime an der Uhr des Geraets' );
};

# Runde 2: 2>/dev/null verschluckt die Fehlermeldungen des Befehls
subtest '2>/dev/null: Fehlermeldungen des Befehls verschwinden' => sub {
    fresh();
    my ( $o, $ok ) = sh('grep -r x /var/log/syslog /var/log/cron* 2>/dev/null');
    is( $o, '', 'grep: Meldungen weg' );
    ok( !$ok, '... Status bleibt' );
    is( scalar sh('ls /nope /etc/app 2>/dev/null'), "/etc/app:\napp.conf", 'ls: nur die Liste' );
    is( scalar sh('cat /nope 2>/dev/null || echo fehlt'), 'fehlt', 'cat … || echo' );
    is( scalar sh('cd /nope 2>/dev/null; pwd'), '/root', 'cd: Meldung der bash weg' );
    like( scalar sh('cat /nope 2>&1'), qr/No such file/, '2>&1: Meldung bleibt' );
    like( scalar sh('cat /nope /etc/app/app.conf 2>/dev/null | head -n 1'), qr/\Aa=1\z/, 'in der Pipe' );
    like( scalar sh('cat /nope; ls /nope 2>/dev/null'), qr/\Acat: \/nope: No such file or directory\z/, 'nur der Befehl mit der Umleitung' );
};

# Runde 2: ping -c1 schickt ein Paket, nicht vier
subtest 'ping -cN zusammengeschrieben' => sub {
    $state = { h => { type => 'linux', interfaces => { eth0 => { addr => ['10.0.0.2/24'], state => 'UP' } },
        routes => [ { dst => 'default', via => '10.0.0.1', dev => 'eth0' }, { dst => '10.0.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.0.0.2' } ] } };
    like( sh( 'ping -c1 -W2 10.0.0.1', 'h' ), qr/^1 packets transmitted, 1 received/m, 'ping -c1' );
    like( sh( 'ping -c 2 10.0.0.1', 'h' ), qr/^2 packets transmitted/m, 'ping -c 2' );
    my ( $o, $ok ) = sh( 'nft list ruleet', 'h' );
    ok( !$ok && $o =~ /\AError: syntax error/, 'nft list mit Tippfehler: Syntaxfehler' );
};

# Runde 3: als Benutzer zaehlen x (Durchqueren) und r (Lesen) an
# Verzeichnissen, rm braucht w+x am Elternordner (sticky: nur der Eigentuemer)
subtest 'Rechte an Verzeichnissen fuer cd, ls, cat, head, rm, Umleitung' => sub {
    $state = {
        nas => {
            type   => 'linux',
            users  => { anna => { uid => 1001, groups => [ 'anna', 'redaktion' ] }, gast => { uid => 1004, groups => ['gast'] } },
            groups => { redaktion => { gid => 1101 } },
            dirs   => { '/srv/redaktion' => { owner => 'root', group => 'redaktion', mode => '2770' },
                '/srv/redaktion/artikel' => { owner => 'root', group => 'redaktion', mode => '2770' } },
            files  => { '/srv/redaktion/artikel/a.md' => { owner => 'anna', group => 'redaktion', mode => '0660', content => "text\n" },
                '/tmp/f' => { owner => 'anna', group => 'anna', mode => '0666', content => "x\n" } },
        },
    };
    my $as = sub { my ( $u, $c ) = @_; my ( $o, $ok ) = sh( "su - $u -c '$c'", 'nas' ); return wantarray ? ( $o, $ok ) : $o };
    my ( $o, $ok ) = $as->( gast => 'cd /srv/redaktion/artikel && ls' );
    is( $o, 'bash: cd: /srv/redaktion/artikel: Permission denied', 'cd: kein x auf dem Weg' );
    ok( !$ok, '... Fehlstatus' );
    is( scalar $as->( gast => 'ls /srv/redaktion' ), q{ls: cannot open directory '/srv/redaktion': Permission denied}, 'ls: kein r am Verzeichnis' );
    is( scalar $as->( gast => 'ls /srv/redaktion/artikel' ), q{ls: cannot access '/srv/redaktion/artikel': Permission denied}, 'ls: kein x auf dem Weg' );
    is( scalar $as->( gast => 'cat /srv/redaktion/artikel/a.md' ), 'cat: /srv/redaktion/artikel/a.md: Permission denied', 'cat' );
    is( scalar $as->( gast => 'head -n 1 /srv/redaktion/artikel/a.md' ), q{head: cannot open '/srv/redaktion/artikel/a.md' for reading: Permission denied}, 'head' );
    like( scalar $as->( gast => 'echo x >> /srv/redaktion/artikel/a.md' ), qr/Permission denied/, 'Umleitung: kein x auf dem Weg' );
    ( $o, $ok ) = $as->( gast => 'rm /srv/redaktion/artikel/a.md' );
    is( $o, q{rm: cannot remove '/srv/redaktion/artikel/a.md': Permission denied}, 'rm: kein Recht am Elternordner' );
    ok( exists $state->{nas}{files}{'/srv/redaktion/artikel/a.md'}, '... Datei bleibt' );
    $as->( gast => 'rm -f /srv/redaktion/artikel/a.md' );
    ok( exists $state->{nas}{files}{'/srv/redaktion/artikel/a.md'}, 'rm -f: Datei bleibt' );
    ( $o, $ok ) = $as->( gast => 'rm /tmp/f' );
    like( $o, qr/Permission denied/, 'rm in /tmp (sticky): nur der Eigentuemer' );
    is( scalar $as->( anna => 'cd /srv/redaktion/artikel && ls && cat a.md' ), "a.md\ntext", 'anna (Gruppe): cd, ls, cat' );
    ( $o, $ok ) = $as->( anna => 'rm /srv/redaktion/artikel/a.md' );
    ok( $ok && !exists $state->{nas}{files}{'/srv/redaktion/artikel/a.md'}, 'anna darf loeschen' );
    ok( ( sh( 'ls /srv/redaktion/artikel', 'nas' ) )[1], 'root: immer' );
};

# Runde 3: trap … EXIT laeuft am Ende der Shell (auch bei
# exit und set -e); andere Signale werden gemerkt; od -c zeigt Bytes wie GNU od
subtest 'trap EXIT und od -c' => sub {
    fresh();
    is( scalar sh(q{bash -c 'trap "echo bye" EXIT; echo hi'}), "hi\nbye", 'bash -c: EXIT-Handler am Ende' );
    is( scalar sh(q{trap 'echo bye' EXIT; echo hi}), "hi\nbye", 'Befehlszeile: am Ende' );
    $state->{srv}{files}{'/usr/local/bin/s.sh'} = { mode => '0755', content =>
        qq{#!/bin/bash\nset -e\nTEMP=/tmp/s.tmp\ntouch "\$TEMP"\ntrap 'rm -f "\$TEMP"' EXIT INT TERM\necho arbeitet\nfalse\necho nie\n} };
    my ( $o, $ok ) = sh('/usr/local/bin/s.sh; echo "rc=$?"');
    is( $o, "arbeitet\nrc=1", 'set -e: Abbruch, Status 1' );
    ok( !exists $state->{srv}{files}{'/tmp/s.tmp'}, '... und der Handler hat aufgeraeumt' );
    $state->{srv}{files}{'/usr/local/bin/e.sh'} = { mode => '0755', content => qq{#!/bin/sh\ntrap 'echo ende' EXIT\nexit 3\n} };
    is( scalar sh('/usr/local/bin/e.sh; echo "rc=$?"'), "ende\nrc=3", 'exit 3: Handler, Status bleibt 3' );
    is( scalar sh(q{bash -c 'trap "echo bye" EXIT; trap - EXIT; echo hi'}), 'hi', 'trap - EXIT nimmt ihn zurueck' );
    is( scalar sh(q{bash -c 'trap "echo x" INT TERM; trap -p'}), "trap -- 'echo x' SIGINT\ntrap -- 'echo x' SIGTERM", 'trap -p' );
    is( scalar sh(q{bash -c 'trap "echo aus" EXIT; ( echo sub ); echo hi'}), "sub\nhi\naus", 'Subshell loest ihn nicht aus' );
    is( scalar sh(q{printf 'hi\n' | od -c}), "0000000   h   i  \\n\n0000003", 'od -c aus der Pipe' );
    is( scalar sh('od -c /etc/app/app.conf'), "0000000   a   =   1  \\n\n0000004", 'od -c DATEI' );
    is( scalar sh(q{printf 'a\tb' | od -An -c}), "   a  \\t   b", 'od -An -c' );
    is( scalar sh(q{printf 'ä' | od -c}), "0000000 303 244\n0000002", 'od -c: Bytes ausserhalb ASCII oktal' );
    is( scalar sh(q{printf 'hi\n' | od -An -tx1}), ' 68 69 0a', 'od -An -tx1' );
    is( scalar sh(q{printf 'abcdefghijklmnopq' | od -t x1}), "0000000 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70\n0000020 71\n0000021", 'od -t x1 mit Adressen' );
};

# Runde 3: env zeigt die Umgebung der Shell
subtest 'env' => sub {
    fresh();
    my $e = sh('env');
    like( $e, qr/^PATH=\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin$/m, 'PATH' );
    like( $e, qr/^HOME=\/root$/m, 'HOME' );
    like( $e, qr/^USER=root$/m, 'USER' );
    like( scalar sh('export FOO=bar; env | grep ^FOO='), qr/\AFOO=bar\z/, 'exportierte Variable' );
    is( scalar sh('X=1; env | grep -c ^X='), '0', 'nicht exportierte Variable fehlt' );
    is( scalar sh('env LANG=de_DE.UTF-8 env | grep ^LANG='), 'LANG=de_DE.UTF-8', 'env NAME=wert befehl' );
};

# Runde 3: TCP von Geraet A zu Geraet B im Zustand —
# Firewall (nft input von B, erste passende Regel, Policy) und Lauscher von B
subtest 'TCP-Probe: nc, /dev/tcp, wget, curl zwischen Geraeten' => sub {
    my $why = need_parts('Sshd');
    plan skip_all => $why if $why;
    my $T = JSON::MaybeXS::true();
    $state = {
        a => { type => 'linux', interfaces => { eth0 => { addr => ['10.0.0.2/24'], state => 'UP' } },
            routes => [ { dst => '10.0.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.0.0.2' } ],
            files => { '/usr/bin/nc' => { mode => '0755', content => '' }, '/usr/bin/curl' => { mode => '0755', content => '' } } },
        b => { type => 'linux', interfaces => { eth0 => { addr => ['10.0.0.3/24'], state => 'UP' } },
            routes => [ { dst => '10.0.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.0.0.3' } ],
            nft => { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input', priority => '0', policy => 'drop', rules => [
                'ct state established,related accept', 'iif lo accept', 'ip saddr 10.0.0.2 tcp dport 22 accept', 'tcp dport 9999 reject',
                'tcp dport { 80, 8080 } accept', 'log prefix "drop: " counter drop' ] } } } },
            services => { ssh => { active => $T, exec => 'sshd' }, postgresql => { active => $T, exec => 'postgres' },
                app => { active => $T, exec => 'app', listen => ['127.0.0.1:8080'] } } },
        c => { type => 'linux', interfaces => { eth0 => { addr => ['10.0.0.4/24'], state => 'UP' } },
            routes => [ { dst => '10.0.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.0.0.4' } ],
            services => { ssh => { active => $T, exec => 'sshd' } } },
        d => { type => 'linux', interfaces => { eth0 => { addr => ['10.0.0.5/24'], state => 'UP' } },
            services => { geheim => { active => $T, description => 'eigener Dienst' } } },
    };
    my ( $o, $ok, $gap ) = sh( 'nc -zv 10.0.0.3 22', 'a' );
    is( $o, 'Connection to 10.0.0.3 22 port [tcp/ssh] succeeded!', 'nc: erlaubt und lauscht' );
    ( $o, $ok ) = sh( 'nc -zv -w 2 b 5432', 'a' );
    is( $o, 'nc: connect to b port 5432 (tcp) timed out: Operation now in progress', 'nc: Policy drop' );
    ok( !$ok, '... Fehlstatus' );
    is( scalar sh( 'nc -zv 10.0.0.3 9999', 'a' ), 'nc: connect to 10.0.0.3 port 9999 (tcp) failed: Connection refused', 'nc: reject' );
    is( scalar sh( 'nc -zv 10.0.0.3 8080', 'a' ), 'nc: connect to 10.0.0.3 port 8080 (tcp) failed: Connection refused', 'nc: erlaubt, lauscht nur auf 127.0.0.1' );
    is( scalar sh( 'nc -zv 10.0.0.4 5432', 'a' ), 'nc: connect to 10.0.0.4 port 5432 (tcp) failed: Connection refused', 'nc: ohne Firewall, kein Lauscher' );
    ( $o, $ok ) = sh( 'nc -z 10.0.0.4 22', 'a' );
    ok( $ok && $o eq '', 'nc -z ohne -v: still' );
    ( $o, $ok, $gap ) = sh( 'nc -zv 10.0.0.99 22', 'a' );
    like( $o, qr/failed: No route to host\z/, 'unbekannter Rechner im eigenen Netz: es gibt ihn nicht (ADR 0012)' );
    ok( !$ok && !defined $gap, '… gescheitert, ohne Luecke' );
    ( $o, $ok, $gap ) = sh( 'nc -zv 10.0.0.5 4711', 'a' );
    ok( defined $gap, 'Rechner mit Dienst unbekannter Ports: Luecke' );
    ( $o, $ok, $gap ) = sh( 'nc -zv 10.0.0.3 22', 'c' );
    like( $o, qr/command not found/, 'nc nicht installiert: command not found' );
    ( $o, $ok ) = sh( q{bash -c 'echo > /dev/tcp/10.0.0.3/22' && echo offen}, 'a' );
    is( $o, 'offen', '/dev/tcp: offen' );
    is( scalar sh( q{timeout 2 bash -c 'echo > /dev/tcp/10.0.0.3/5432' && echo offen || echo "zu rc=$?"}, 'a' ), 'zu rc=124', '/dev/tcp mit timeout: 124' );
    like( scalar sh( q{bash -c 'echo > /dev/tcp/10.0.0.4/80'}, 'a' ), qr/\Abash: connect: Connection refused\nbash: \/dev\/tcp\/10\.0\.0\.4\/80: Connection refused\z/, '/dev/tcp: refused' );
    is( scalar sh( q{timeout 2 bash -c "echo > /dev/tcp/10.0.0.4/80" 2>/dev/null && echo offen}, 'a' ), '', '2>/dev/null hinter timeout bash -c' );
    ok( ( sh( q{bash -c 'echo > /dev/tcp/127.0.0.1/8080'}, 'b' ) )[1], '/dev/tcp lokal: lauscht auf 127.0.0.1' );
    like( scalar sh( 'wget -O- http://10.0.0.3:5432/', 'a' ), qr/Connecting to 10\.0\.0\.3 \(10\.0\.0\.3:5432\)\.\.\. failed: Connection timed out\.\z/, 'wget: timed out' );
    like( scalar sh( 'wget -O- http://10.0.0.4/', 'a' ), qr/failed: Connection refused\.\z/, 'wget: refused' );
    is( scalar sh( 'wget -q -O- http://10.0.0.4/', 'a' ), '', 'wget -q: still' );
    is( scalar sh( 'curl -sS http://10.0.0.4:81/', 'a' ), q{curl: (7) Failed to connect to 10.0.0.4 port 81 after 0 ms: Couldn't connect to server}, 'curl: refused' );
    ( $o, $ok ) = sh( 'curl -s http://10.0.0.4:81/; echo "rc=$?"', 'a' );
    is( $o, 'rc=7', 'curl -s: still, Status 7' );
    like( scalar sh( 'curl http://10.0.0.4/', 'c' ), qr/command not found/, 'curl nicht installiert' );
};

# Runde 3: awk mit Summen, END, printf, Arrays, if
subtest 'awk: Variablen, END, printf, Arrays' => sub {
    my $awk = sub { my $in = shift; ( Langertha::Holmgang::Shell::Filter::filter_output( $in, [ 'awk', @_ ] ) )[0] };
    my $du = "1073741824 a.log\n536870912 b.log\n2147483648 c.log";
    is( $awk->( $du, '{s+=$1} END {printf "%.1f GB in %d Dateien\n", s/1024/1024/1024, NR}' ), '3.5 GB in 3 Dateien', 'Summe, END, printf %.1f %d' );
    is( $awk->( $du, '{ if ($1 > 1000000000) big++; else small++ } END { print big, small }' ), '2 1', 'if/else, ++' );
    is( $awk->( "web1 500\nweb2 200\nweb1 502\nweb1 200", '$2 >= 500 { c[$1]++ } END { for (h in c) print h, c[h] }' ), 'web1 2', 'Array, for (k in a)' );
    is( $awk->( "a 1\nb 2\na 3", '{ s[$1] += $2 } END { for (k in s) printf "%s=%d\n", k, s[k] }' ), "a=4\nb=2", 'Summe je Schluessel' );
    is( $awk->( "x\ny", 'BEGIN { n = 0 } { n = n + 1 } END { print "Zeilen: " n }' ), 'Zeilen: 2', 'Zuweisung und Verkettung' );
    is( $awk->( "5\n7", '{ m = ($1 > m) ? $1 : m }' ) // 'LUECKE', 'LUECKE', '?: ist (noch) eine Luecke' );
    is( $awk->( "a\nb", 'END { print NR " Zeilen" }' ), '2 Zeilen', 'nur END' );
    is( $awk->( "3.7", '{ print int($1), length($1) }' ), '3 3', 'int, length' );
    is( $awk->( "k v", '("k" in seen) { print "nie" } { seen[$1] = 1 } END { if ("k" in seen) print "da" }' ), 'da', 'in' );
    fresh();
    is( scalar sh(q{printf '10 x\n20 y\n' | awk '{s+=$1} END {print s}'}), '30', 'in der Shell' );
};

# Runde 3: last, last reboot, lastlog aus dem Zustand (logins) und dem
# laufenden Start; journalctl -k ohne Kernel-Meldungen im Zustand
subtest 'last, lastlog, journalctl -k' => sub {
    fresh();
    my $l = sh('last');
    like( $l, qr/\Areboot   system boot  6\.1\.0-26-amd64   Tue Oct 20 09:00   still running\n\nwtmp begins Tue Oct 20 09:00:00 2026\z/, 'last ohne Anmeldungen: nur der Start' );
    is( scalar sh('last reboot | head -1'), 'reboot   system boot  6.1.0-26-amd64   Tue Oct 20 09:00   still running', 'last reboot' );
    $state->{srv}{users} = { ops => { uid => 1000, groups => ['ops'] } };
    $state->{srv}{logins} = [ { user => 'ops', tty => 'pts/0', from => '10.0.0.5', start => 'Mon Oct 19 16:02', end => '16:40' } ];
    $l = sh('last -a');
    like( $l, qr/^ops      pts\/0        Mon Oct 19 16:02 - 16:40  \(00:38\)     10\.0\.0\.5$/m, 'last -a: Anmeldung aus dem Zustand, Rechner am Ende' );
    like( sh('last'), qr/^ops      pts\/0        10\.0\.0\.5         Mon Oct 19 16:02 - 16:40  \(00:38\)$/m, 'last: Rechner in der dritten Spalte' );
    unlike( sh('last reboot'), qr/^ops/m, 'last reboot: nur Starts' );
    like( sh('last ops'), qr/\Aops /, 'last BENUTZER' );
    my $ll = sh('lastlog');
    like( $ll, qr/\AUsername +Port +From +Latest\nroot +\*\*Never logged in\*\*\nops +pts\/0 +10\.0\.0\.5 +Mon Oct 19 16:02:00 \+0200 2026\z/, 'lastlog' );
    my ( $o, $ok, $gap ) = sh('journalctl -k');
    is( $o, '-- No entries --', 'journalctl -k: keine Kernel-Meldungen' );
    ok( $ok && !defined $gap, '... ohne Luecke' );
    is( scalar sh('journalctl --dmesg -n 5'), '-- No entries --', 'journalctl --dmesg' );
    is( scalar sh('uptime'), ' 14:00:00 up  5:00,  1 user,  load average: 0.08, 0.03, 0.01', 'uptime: seit dem laufenden Start' );
    is( scalar sh('uptime -s'), '2026-10-20 09:00:00', 'uptime -s' );
    is( scalar sh('uptime -p'), 'up 5 hours', 'uptime -p' );
};

# Runde 3: ein Name, den der Resolver nicht kennt (wie getent hosts)
subtest 'TCP-Probe: Name nicht aufloesbar' => sub {
    fresh();
    $state->{srv}{files}{'/usr/bin/nc'} = { mode => '0755', content => '' };
    is( scalar sh('wget -O- http://registrar.example.invalid/'), q{wget: unable to resolve host address 'registrar.example.invalid'}, 'wget' );
    is( scalar sh('nc -zv registrar.example.invalid 443'), q{nc: getaddrinfo for host "registrar.example.invalid" port 443: Name or service not known}, 'nc' );
    like( scalar sh(q{bash -c 'echo > /dev/tcp/registrar.example.invalid/443'}), qr/\Abash: registrar\.example\.invalid: Name or service not known\n/, '/dev/tcp' );
    ok( !( sh('getent hosts registrar.example.invalid') )[1], '... wie getent hosts' );
    my ( $o, $ok, $gap ) = sh('wget -O- http://10.40.0.2/');
    ok( defined $gap, 'Adresse ohne Geraet im Zustand: Luecke (es kann ihn geben)' );
};

# Runde 3: Shell-Funktionen, ! befehl, #!/usr/bin/env bash,
# bash -n, read -d "", which flock/logger; <( ) ist eine Luecke statt einer falschen Meldung
subtest 'Shell: Funktionen, !, env-Shebang, bash -n, read -d' => sub {
    fresh();
    is( scalar sh(q{bash -c 'f() { echo "funktion $1"; }; f ARG1; echo ende'}), "funktion ARG1\nende", 'Funktion mit Argument' );
    $state->{srv}{files}{'/tmp/h.sh'} = { mode => '0755', content =>
        qq{#!/usr/bin/env bash\nlog() {\n  echo "[log] \$*"\n}\nfunction pruefe {\n  [ -f "\$1" ] || return 3\n  echo da\n}\nlog start\npruefe /etc/app/app.conf\npruefe /fehlt; echo "rc=\$?"\nlog ende\n} };
    my ( $o, $ok, $gap ) = sh('/tmp/h.sh');
    is( $o, "[log] start\nda\nrc=3\n[log] ende", '#!/usr/bin/env bash, Funktionen, return N' );
    ok( $ok && !defined $gap, '... ohne Luecke' );
    is( scalar sh('! grep -q x /etc/app/app.conf && echo "kein x"'), 'kein x', '! befehl' );
    is( scalar sh('if ! test -f /fehlt; then echo fehlt; fi'), 'fehlt', 'if ! …' );
    ( $o, $ok ) = sh('bash -n /tmp/h.sh && echo "Syntax OK"');
    is( $o, 'Syntax OK', 'bash -n: nur pruefen' );
    $state->{srv}{files}{'/tmp/kaputt.sh'} = { mode => '0755', content => "if true; then\necho x\n" };
    ( $o, $ok ) = sh('bash -n /tmp/kaputt.sh');
    ok( !$ok && $o =~ /syntax error/, 'bash -n: Syntaxfehler' );
    ok( !exists $state->{srv}{files}{'/tmp/x'}, 'bash -n fuehrt nichts aus' );
    $state->{srv}{files}{'/tmp/d/a'} = "1\n";
    $state->{srv}{files}{'/tmp/d/b'} = "2\n";
    is( scalar sh(q{find /tmp/d -type f -print0 | while IFS= read -r -d "" f; do echo "got:$f"; done}), "got:/tmp/d/a\ngot:/tmp/d/b", 'read -d ""' );
    like( scalar sh('which flock logger'), qr{\A/usr/bin/flock\n/usr/bin/logger\z}, 'flock, logger gibt es' );
    is( scalar sh('n=0; while IFS= read -r -d "" f; do n=$((n+1)); done < <(find /tmp/d -type f -print0); echo "n=$n"'), 'n=2', 'done < <( befehl )' );
    ( $o, $ok, $gap ) = sh('cat < <(ls /tmp/d)');
    ok( defined $gap && $o !~ /No such file/, 'befehl < <( … ): Luecke statt falscher Meldung' );
};

done_testing;
