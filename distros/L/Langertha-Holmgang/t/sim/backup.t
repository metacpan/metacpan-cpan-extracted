#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command need_parts );
use Langertha::Holmgang::Shell::Filter ();

# Sichern und Wiederherstellen auf dem Linux-Simulator.
# Behauptet wird: tar entfernt das fuehrende /, packt ohne -C ins aktuelle
# Verzeichnis (cd, sonst /root) aus, erhaelt als root Eigentuemer/Rechte/Zeit,
# -k ueberschreibt nicht, ein beschaedigtes Archiv bricht ab; rsync kopiert mit
# Schraegstrich den Inhalt, ohne das Verzeichnis, --delete loescht nur unterhalb
# des Ziels und schont Ausgeschlossenes, nur -a erhaelt Eigentuemer; cp ohne -a
# macht root zum Eigentuemer, eine vorhandene Datei behaelt ihre Rechte;
# sha256sum -c erkennt Abweichungen; restic restauriert aus dem gewaehlten
# Snapshot, rechnet die Aufbewahrung wie restic (je Host und Pfaden), gibt
# Platz erst mit prune frei, scheitert an einer veralteten Sperre bis unlock und
# ohne das richtige Passwort; find -delete loescht die Treffer.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

sub f { my ( $c, %o ) = @_; return { content => $c, owner => 'root', group => 'root', mode => '0644', mtime => 'Oct 01 10:00', %o } }

sub world {
    my $snap = sub {
        my ( $id, $t, $host, %x ) = @_;
        return { id => $id, time => $t, host => $host, paths => ['/srv/www'], tags => [], unique => '1G', files => { '/srv/www/index.html' => f("v $id\n", owner => 'www-data') }, %x };
    };
    return {
        web1 => {
            type => 'linux', hostname => 'web1', restic => JSON::MaybeXS::true(),
            interfaces => { eth0 => { addr => ['10.20.0.11/24'], state => 'UP' } },
            files => {
                '/etc/nginx/nginx.conf' => f("neu\n", mtime => 'Oct 20 09:00'),
                '/etc/nginx/sites-available/shop.conf' => undef,
                '/srv/www/index.html'  => f("aktuell\n", owner => 'www-data', group => 'www-data'),
                '/srv/www/cache/x.tmp' => f("tmp\n"),
                '/srv/www/neu.html'    => f("neu\n"),
                '/backup/www/alt.html' => f("alt\n"),
                '/backup/db/dump.sql'  => f("db\n"),
                '/root/.restic-pass'   => f("geheim\n", mode => '0600'),
                '/var/backups/etc.tar.gz' => { size => '2M', mtime => 'Oct 19 23:30', sha256 => 'a' x 64,
                    tar => { 'etc/nginx/nginx.conf' => f("alt\n"), 'etc/nginx/sites-available/shop.conf' => f("shop\n", mode => '0640', group => 'www-data') } },
                '/var/backups/kaputt.tar.gz' => { size => '1M', corrupt => JSON::MaybeXS::true(), sha256 => 'b' x 64, tar => { 'etc/a' => f('a'), 'etc/b' => f('b') } },
                '/var/backups/SHA256SUMS' => ( 'a' x 64 ) . "  etc.tar.gz\n" . ( 'c' x 64 ) . "  kaputt.tar.gz\n",
            },
        },
        backup1 => {
            type => 'linux', hostname => 'backup1', interfaces => { eth0 => { addr => ['10.20.0.50/24'], state => 'UP' } },
            files => { '/srv/mirror/web1/etc/ssl/shop.key' => f("KEY\n", mode => '0600', owner => 'root', group => 'ssl-cert') },
            restic_repos => { '/srv/restic' => {
                password_file => '/root/.restic-pass', size => '20G',
                snapshots => [
                    $snap->( 'a1000001', '2026-10-12 23:30:00', 'web1' ), $snap->( 'a1000002', '2026-10-13 23:30:00', 'web1' ),
                    $snap->( 'a1000003', '2026-10-18 23:30:00', 'web1' ), $snap->( 'a1000004', '2026-10-19 11:00:00', 'web1' ),
                    $snap->( 'a1000005', '2026-10-19 23:30:00', 'web1' ), $snap->( 'b2000001', '2026-10-10 23:30:00', 'db1' ),
                ] } },
        },
    };
}
delete world()->{web1}{files}{'/etc/nginx/sites-available/shop.conf'};
sub run { my ( $s, $h, $c ) = @_; my ( $o, $ok ) = run_command( $s, $h, $c ); return wantarray ? ( $o, $ok ) : $o }
sub F { my ( $s, $h, $p ) = @_; return $s->{$h}{files}{$p} }

subtest tar => sub {
    my $s = world();
    delete $s->{web1}{files}{'/etc/nginx/sites-available/shop.conf'};
    like( run( $s, 'web1', 'tar -tzvf /var/backups/etc.tar.gz' ), qr{-rw-r----- root/www-data .* etc/nginx/sites-available/shop\.conf}, 'tar -tv' );
    my ( $o, $ok ) = run( $s, 'web1', 'tar -xzf /var/backups/etc.tar.gz etc/nginx/sites-available/shop.conf' );
    ok( $ok, 'ohne -C' );
    is( F( $s, 'web1', '/root/etc/nginx/sites-available/shop.conf' )->{content}, "shop\n", '… landet unter /root' );
    run( $s, 'web1', 'cd / && tar xzf /var/backups/etc.tar.gz /etc/nginx/sites-available/shop.conf' );
    is( F( $s, 'web1', '/etc/nginx/sites-available/shop.conf' )->{mode}, '0640', 'nach cd /, fuehrendes / entfernt, Rechte erhalten' );
    is( F( $s, 'web1', '/etc/nginx/nginx.conf' )->{content}, "neu\n", 'andere Mitglieder unberuehrt' );
    ( $o, $ok ) = run( $s, 'web1', 'tar -xzf /var/backups/etc.tar.gz -C / etc/fehlt' );
    ok( !$ok, 'fehlendes Mitglied' );
    like( $o, qr/etc\/fehlt: Not found in archive/, '… Meldung' );
    run( $s, 'web1', 'tar -xkzf /var/backups/etc.tar.gz -C /' );
    is( F( $s, 'web1', '/etc/nginx/nginx.conf' )->{content}, "neu\n", '-k ueberschreibt nicht' );
    run( $s, 'web1', 'tar -xzf /var/backups/etc.tar.gz -C /' );
    is( F( $s, 'web1', '/etc/nginx/nginx.conf' )->{content}, "alt\n", 'ganzes Archiv ueberschreibt' );
    ( $o, $ok ) = run( $s, 'web1', 'tar -tzf /var/backups/kaputt.tar.gz' );
    ok( !$ok, 'beschaedigt' );
    like( $o, qr/Unexpected EOF in archive/, '… wie GNU tar' );
    run( $s, 'web1', 'tar czf /root/www.tgz /srv/www' );
    ok( F( $s, 'web1', '/root/www.tgz' )->{tar}{'srv/www/index.html'}, 'tar c' );
    is( run( $s, 'web1', 'tar -xOzf /var/backups/etc.tar.gz etc/nginx/nginx.conf' ), 'alt', 'tar -O' );
};

subtest rsync => sub {
    my $s = world();
    run( $s, 'web1', 'rsync -a /srv/www /backup/www/' );
    ok( F( $s, 'web1', '/backup/www/www/index.html' ), 'ohne Schraegstrich: Verzeichnis darunter' );
    $s = world();
    run( $s, 'web1', 'rsync -a --delete --exclude cache/ /srv/www/ /backup/www/' );
    is( F( $s, 'web1', '/backup/www/index.html' )->{owner}, 'www-data', 'mit Schraegstrich: Inhalt, -a erhaelt Eigentuemer' );
    ok( !F( $s, 'web1', '/backup/www/alt.html' ), '--delete loescht im Ziel' );
    ok( !F( $s, 'web1', '/backup/www/cache/x.tmp' ), 'cache ausgeschlossen' );
    ok( F( $s, 'web1', '/backup/db/dump.sql' ), 'Nachbarverzeichnis bleibt' );
    $s = world();
    run( $s, 'web1', 'rsync -r /srv/www/ /backup/www/' );
    is( F( $s, 'web1', '/backup/www/index.html' )->{owner}, 'root', 'nur -r: Eigentuemer root' );
    $s = world();
    run( $s, 'web1', 'rsync -a --delete /srv/www/ /backup/' );
    ok( !F( $s, 'web1', '/backup/db/dump.sql' ), '--delete auf das falsche Ziel loescht Fremdes' );
    $s = world();
    run( $s, 'web1', 'rsync -av backup1:/srv/mirror/web1/etc/ssl/shop.key /etc/ssl/private/' );
    is( F( $s, 'web1', '/etc/ssl/private/shop.key' )->{group}, 'ssl-cert', 'von einem anderen Geraet' );
    $s = world();
    run( $s, 'web1', 'rsync -an --delete /srv/www/ /backup/www/' );
    ok( F( $s, 'web1', '/backup/www/alt.html' ), '-n aendert nichts' );
};

subtest 'cp und find' => sub {
    my $s = world();
    run( $s, 'web1', 'cp /srv/www/index.html /root/' );
    is( F( $s, 'web1', '/root/index.html' )->{owner}, 'root', 'cp ohne -a: root' );
    run( $s, 'web1', 'cp -a /srv/www/index.html /root/b.html' );
    is( F( $s, 'web1', '/root/b.html' )->{owner}, 'www-data', 'cp -a erhaelt' );
    run( $s, 'web1', 'cp /root/etc.conf /srv/www/index.html; cp /etc/nginx/nginx.conf /srv/www/index.html' );
    is( F( $s, 'web1', '/srv/www/index.html' )->{owner}, 'www-data', 'vorhandenes Ziel behaelt Eigentuemer' );
    my ( $o, $ok ) = run( $s, 'web1', 'cp /srv/www /root/' );
    like( $o, qr/-r not specified/, 'Verzeichnis ohne -r' );
    run( $s, 'web1', 'cp -r /srv/www /root/' );
    ok( F( $s, 'web1', '/root/www/neu.html' ), 'cp -r' );
    is( run( $s, 'web1', 'find /srv/www -path /srv/www/cache -prune -o -print' ), "/srv/www\n/srv/www/index.html\n/srv/www/neu.html", 'find -prune -o -print' );
    is( run( $s, 'web1', 'find /srv/www -name cache -prune -o -type f -print' ), "/srv/www/index.html\n/srv/www/neu.html", '... -name, nur Dateien' );
    is( run( $s, 'web1', 'find /srv/www -name cache -prune' ), '/srv/www/cache', '... ohne -o: das beschnittene Verzeichnis' );
    run( $s, 'web1', 'find /srv/www -name "*.tmp" -delete' );
    ok( !F( $s, 'web1', '/srv/www/cache/x.tmp' ), 'find -delete' );
    run( $s, 'web1', 'find /backup -mtime +7 -exec rm -f {} \;' );
    ok( !F( $s, 'web1', '/backup/db/dump.sql' ), 'find -mtime -exec rm' );
};

subtest sha256sum => sub {
    my $s = world();
    my ( $o, $ok ) = run( $s, 'web1', 'cd /var/backups && sha256sum -c SHA256SUMS' );
    ok( !$ok, 'Abweichung' );
    like( $o, qr/etc\.tar\.gz: OK\nkaputt\.tar\.gz: FAILED/, '… je Datei' );
    ( $o, $ok ) = run( $s, 'web1', 'gzip -t /var/backups/kaputt.tar.gz' );
    ok( !$ok, 'gzip -t' );
    # Archiv ohne Inhalt und ohne sha256 im Zustand: nicht der Hash der leeren Eingabe;
    # gleiche Mitglieder (Kopie) gleicher Hash, andere Mitglieder ein anderer
    $s->{web1}{files}{'/var/backups/x1.tar.gz'} = { size => '2M', tar => { 'etc/a' => f("1\n") } };
    $s->{web1}{files}{'/var/backups/x2.tar.gz'} = { size => '2M', tar => { 'etc/a' => f("2\n") } };
    run( $s, 'web1', 'cp -p /var/backups/x1.tar.gz /root/x1.tar.gz' );
    my %h = map { ( split /\s+/, $_ )[ 1, 0 ] } split /\n/, run( $s, 'web1', 'sha256sum /var/backups/x1.tar.gz /var/backups/x2.tar.gz /root/x1.tar.gz' );
    isnt( $h{'/var/backups/x1.tar.gz'}, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'Archiv: nicht der Hash von nichts' );
    isnt( $h{'/var/backups/x1.tar.gz'}, $h{'/var/backups/x2.tar.gz'}, '... andere Mitglieder, anderer Hash' );
    is( $h{'/root/x1.tar.gz'}, $h{'/var/backups/x1.tar.gz'}, '... die Kopie hat denselben' );
    ( $o, $ok ) = run( $s, 'web1', 'md5sum /var/backups/x1.tar.gz /root/x1.tar.gz' );
    ok( $ok, 'md5sum auf ein Archiv: keine Luecke' ) or diag $o;
    my @m = map { ( split /\s+/ )[0] } split /\n/, $o;
    ok( @m == 2 && $m[0] eq $m[1] && $m[0] =~ /\A[0-9a-f]{32}\z/, '... gleich fuer die Kopie' ) or diag $o;
};

subtest restic => sub {
    my $s = world();
    my $R = '-r sftp:backup1:/srv/restic --password-file /root/.restic-pass';
    my ( $o, $ok ) = run( $s, 'web1', 'restic -r sftp:backup1:/srv/restic snapshots' );
    ok( !$ok, 'ohne Passwort' );
    like( run( $s, 'web1', "restic $R snapshots --host web1" ), qr/a1000005 .*\n.*\n5 snapshots/s, 'snapshots --host' );
    like( run( $s, 'web1', 'RESTIC_REPOSITORY=sftp:backup1:/srv/restic RESTIC_PASSWORD_FILE=/root/.restic-pass restic snapshots' ), qr/6 snapshots/, 'Umgebung vor dem Befehl' );
    run( $s, 'web1', "restic $R restore a1000003 --target / --include /srv/www/index.html" );
    is( F( $s, 'web1', '/srv/www/index.html' )->{content}, "v a1000003\n", 'restore an den Ort' );
    is( F( $s, 'web1', '/srv/www/index.html' )->{owner}, 'www-data', '… mit Eigentuemer' );
    run( $s, 'web1', "restic $R restore latest --host web1 --target /tmp/r" );
    is( F( $s, 'web1', '/tmp/r/srv/www/index.html' )->{content}, "v a1000005\n", 'latest --host nach /tmp/r' );
    is( run( $s, 'web1', "restic $R dump a1000002 /srv/www/index.html" ), 'v a1000002', 'dump' );
    ( $o, $ok ) = run( $s, 'web1', "restic $R forget --keep-daily 2 --host web1" );
    ok( $ok, 'forget' ) or diag $o;
    is_deeply( [ map { $_->{id} } @{ $s->{backup1}{restic_repos}{'/srv/restic'}{snapshots} } ], [qw( a1000003 a1000005 b2000001 )], 'je Tag einer, neueste zuerst; db1 unberuehrt' )
        or diag $o;
    is( $s->{backup1}{restic_repos}{'/srv/restic'}{prunable}, '3.0G', 'Platz erst nach prune' );
    run( $s, 'web1', "restic $R prune" );
    is( $s->{backup1}{restic_repos}{'/srv/restic'}{size}, '17G', 'prune gibt frei' );
    $s = world();
    run( $s, 'web1', "restic $R forget --keep-last 1 --prune" );
    is( scalar @{ $s->{backup1}{restic_repos}{'/srv/restic'}{snapshots} }, 2, 'ohne --host: je Gruppe (web1, db1) einer' );
    $s = world();
    $s->{backup1}{restic_repos}{'/srv/restic'}{lock} = { host => 'web1', pid => 4711, time => '2026-10-19 23:30:05' };
    ( $o, $ok ) = run( $s, 'web1', "restic $R backup /srv/www" );
    ok( !$ok, 'Sperre' );
    like( $o, qr/already locked by PID 4711/, '… Meldung' );
    run( $s, 'web1', "restic $R unlock && restic $R backup /srv/www" );
    is( scalar @{ $s->{backup1}{restic_repos}{'/srv/restic'}{snapshots} }, 7, 'nach unlock: neuer Snapshot' );
};

# forget mit IDs: "latest" waehlt wie restic 0.14 den neuesten Snapshot unter den
# Filtern (--host, --path, --tag); ohne Filter den neuesten ueberhaupt (k32)
subtest 'restic forget latest' => sub {
    my $R = '-r sftp:backup1:/srv/restic --password-file /root/.restic-pass';
    my $ids = sub { [ map { $_->{id} } @{ $_[0]{backup1}{restic_repos}{'/srv/restic'}{snapshots} } ] };
    my $s = world();
    $s->{backup1}{restic_repos}{'/srv/restic'}{snapshots}[-1]{time} = '2026-10-20 01:00:00';    # db1 zuletzt
    my ( $o, $ok ) = run( $s, 'web1', "restic $R forget latest --host web1" );
    ok( $ok, 'forget latest --host' ) or diag $o;
    unlike( $o, qr/\.pm line \d+|Can't use/, '… keine Perl-Meldung in der Ausgabe' );
    is_deeply( $ids->($s), [qw( a1000001 a1000002 a1000003 a1000004 b2000001 )], '… der neueste von web1 ist weg' );
    ( $o, $ok ) = run( $s, 'web1', "restic $R forget latest" );
    ok( $ok, 'forget latest ohne Filter' ) or diag $o;
    is_deeply( $ids->($s), [qw( a1000001 a1000002 a1000003 a1000004 )], '… der neueste ueberhaupt (db1) ist weg' );
};

# Snapshots ohne paths im Zustand (ein knapp geschriebener Fall) lassen restic
# nicht sterben: jeder Befehl antwortet wie mit leerer Pfadliste, ohne Luecke
# (k58).
subtest 'restic: Snapshots ohne paths' => sub {
    my $R = '-r sftp:backup1:/srv/restic --password-file /root/.restic-pass';
    my $bare = sub { my $s = world(); delete $_->{paths} for @{ $s->{backup1}{restic_repos}{'/srv/restic'}{snapshots} }; $s };
    for my $c ( 'snapshots', 'snapshots --path /srv/www', 'ls a1000002', 'restore a1000002 --target /tmp/r', 'forget --keep-last 1' ) {
        my $s = $bare->();
        my ( $o, $ok, $gap ) = run_command( $s, 'web1', "restic $R $c" );
        unlike( $o, qr/ line \d+|ARRAY|\.pm\b/, "restic $c: keine Perl-Meldung" );
        is( $gap, undef, '... und keine Luecke' );
        next unless $c =~ /\A(?:snapshots|ls)\b/;
        is_deeply( $s->{backup1}{restic_repos}, $bare->()->{backup1}{restic_repos}, '... und legt keine paths an' );
    }
    my ( $o ) = run_command( world(), 'web1', "restic $R ls a1000002" );
    my ( $o2 ) = do { my $x = world(); delete $x->{backup1}{restic_repos}{'/srv/restic'}{snapshots}[1]{paths}; run_command( $x, 'web1', "restic $R ls a1000002" ) };
    like( $o2, qr/\Asnapshot a1000002 of \[\] at /, 'ls: leere Pfadliste im Kopf' );
    like( $o, qr/\Asnapshot a1000002 of \[\/srv\/www\] at /, '... mit paths wie bisher' );
};

# Stirbt restic im Simulator mitten in einer Kette, erreicht kein Perl-Text das
# Modell; die anderen Glieder laufen, der Fehler ist eine Luecke (k32-Waechter
# der World; k58).
subtest 'restic stirbt: kein Perl-Text in der Kette' => sub {
    require Langertha::Holmgang::World;
    my $R = '-r sftp:backup1:/srv/restic --password-file /root/.restic-pass';
    my $tools = [ { name => 'run_command', simulator => 'run_command',
        parameters => { type => 'object', properties => { host => { type => 'string' }, command => { type => 'string' } } } } ];
    no warnings qw( redefine once );
    local *Langertha::Holmgang::Sim::Linux::Backup::restic = sub { my $x; return scalar @$x };
    my $w = Langertha::Holmgang::World->new( state => world(), tools => $tools );
    my ( $o, undef, $ok, $gap ) = $w->call( run_command => { host => 'web1', command => "echo vorher; restic $R snapshots | head -1" } );
    unlike( $o, qr/ line \d+|ARRAY|\.pm\b/, 'keine Perl-Meldung' );
    like( $o, qr/\Avorher/, '... die anderen Glieder laufen' );
    ok( !$ok, '... der Aufruf scheitert' );
    like( $gap // '', qr/simulator error: .*ARRAY/, '... der Fehler ist die Luecke' );
};

subtest 'Shell: Umleitungen und $?' => sub {
    my $s = world();
    like( run( $s, 'web1', 'ls /fehlt 2>&1 | head -1' ), qr/cannot access/, '2>&1 laesst die Ausgabe in der Pipe' );
    is( run( $s, 'web1', 'ls /srv/www 2>/dev/null' ), "cache\nindex.html\nneu.html", '2>/dev/null verschluckt die Ausgabe nicht' );
    like( run( $s, 'web1', 'ls /fehlt; echo "rc=$?"; true; echo "rc=$?"' ), qr/rc=1\nrc=0\z/, '$? des vorigen Befehls' );
    like( run( $s, 'web1', 'ls /fehlt; echo "rc=$?"' ), qr/rc=1\z/, '… nach Fehler 1' );
    like( run( $s, 'web1', 'find /srv/www -name "*.html" -exec ls -l {} \;' ), qr{index\.html\n.*neu\.html}, 'find -exec befehl {} \;' );
    like( run( $s, 'web1', 'echo /srv/www/index.html | xargs ls -l' ), qr{www-data .*index\.html}, 'xargs' );
    my ( $d, $dk ) = run( $s, 'web1', 'diff /srv/www/index.html /srv/www/neu.html' );
    ok( !$dk, 'diff: verschieden, Status 1' );
    like( $d, qr/\A1c1\n< aktuell\n---\n> neu\z/, '… mit Zeilen (Normalformat)' );
    like( run( $s, 'web1', 'wc -c < /srv/www/index.html' ), qr/\A8\z/, '< datei als Eingabe' );
    run( $s, 'web1', 'cat /etc/nginx/nginx.conf &>/root/a' );
    is( F( $s, 'web1', '/root/a' ), "neu\n", '&> leitet um' );
};

subtest 'head/tail -c' => sub {
    my $f = sub { ( Langertha::Holmgang::Shell::Filter::filter_output( "abcdefgh", [@_] ) )[0] };
    is( $f->(qw( head -c 3 )), 'abc', 'head -c N' );
    is( $f->(qw( tail -c3 )), 'fgh', 'tail -cN' );
    # -c ohne angehaengte Zahl liest das naechste Wort, nicht $1 eines frueheren Treffers
    is( $f->(qw( head -2 -c 5 )), 'abcde', 'head -2 -c 5: die Zahl hinter -c' );
    is( $f->(qw( tail -n1 -c 2 )), 'gh', 'tail -n1 -c 2' );
};

done_testing;
