#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

if ( my $why = need_parts('Http', 'Docker', 'Nginx', 'Pki') ) { plan skip_all => $why }

# Kleine Werkzeuge der Shell und in Containern: in den ersten
# Messlaeufen haeufig gefragt und bis dahin Luecken der Simulation (Fall
# "unsicher"). Behauptet wird je Werkzeug die Ausgabe wie auf Debian 12 bzw.
# Docker — und dass Lesen den Zustand nicht aendert.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = {
    srv => {
        type => 'linux',
        services => { nginx => { active => 1, exec => 'nginx' }, docker => { active => 1, exec => 'dockerd' } },
        files => {
            '/etc/a.conf' => "eins\nzwei\ndrei\n",
            '/etc/b.conf' => "eins\nZWEI\ndrei\nvier\n",
            '/etc/ssl/live/cert.pem' => { link => '../archive/cert3.pem' },
            '/etc/ssl/archive/cert3.pem' => "PEM\n",
            '/srv/app/compose.yaml' => "services:\n  db:\n    image: postgres:16.4\n    volumes:\n      - pgdata:/var/lib/postgres/data\nvolumes:\n  pgdata:\n",
        },
        pki => { now => '2026-10-24T08:15:00Z' },
        docker => {
            projects => { app => { dir => '/srv/app' } },
            volumes => { app_pgdata => { data => 'kunden' } },
            images => { 'postgres:16.4' => { listens => [5432], data_path => '/var/lib/postgresql/data', tools => ['pg_isready'],
                psql => { tables => [ 'kunden', 'produkte' ], counts => { kunden => 1204 } } } },
        },
    },
};
my $state = clone($start);
sub sh {
    my ( $o, $ok, $gap ) = run_command( $state, 'srv', $_[0] );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}

like( sh('ps aux'), qr/nginx: master process.*\n.*nginx: worker process/s, 'ps aux zeigt nginx mit Worker' );
like( sh('ps -ef | grep dockerd'), qr/dockerd/, 'ps -ef' );
is( sh('date -u'), 'Sat Oct 24 08:15:00 UTC 2026', 'date: Zeit der Umgebung (pki.now)' );
is( sh('date +%F'), '2026-10-24', 'date +%F' );
is( sh('which nginx docker'), "/usr/sbin/nginx\n/usr/bin/docker", 'which kennt simulierte Programme (nginx unter /usr/sbin wie bei Debian)' );
my ( $o, $ok ) = sh('which tcpdump');
ok( !$ok && $o eq '', 'which: nicht installiert -> leer, Exit 1' );
like( sh('md5sum /etc/a.conf'), qr/\A[0-9a-f]{32}  \/etc\/a\.conf\z/, 'md5sum Datei' );
is( sh('cat /etc/a.conf | sha256sum | cut -c1-8'), substr( Digest::SHA::sha256_hex("eins\nzwei\ndrei\n"), 0, 8 ), 'sha256sum aus der Pipe' );
is( sh('echo aGFsbG8= | base64 -d'), 'hallo', 'base64 -d' );
is( sh('readlink -f /etc/ssl/live/cert.pem'), '/etc/ssl/archive/cert3.pem', 'readlink -f folgt dem Verweis' );
is( sh('wc -l /etc/a.conf'), '3 /etc/a.conf', 'wc -l Datei' );
like( sh('wc -c /etc/a.conf /etc/b.conf'), qr/\A\s*15 \/etc\/a\.conf\n\s*20 \/etc\/b\.conf\n\s*35 total\z/, 'wc -c mehrere Dateien mit Summe' );
( $o, $ok ) = sh('diff /etc/a.conf /etc/b.conf');
ok( !$ok, 'diff: Unterschied -> Exit 1' );
like( $o, qr/^< zwei$/m, '... alte Zeile (Normalformat wie GNU diff)' );
like( $o, qr/^> ZWEI$/m, '... neue Zeile' );
like( sh('timeout 5 cat /etc/a.conf'), qr/\Aeins/, 'timeout fuehrt den Befehl aus' );
like( sh('export X=1; env'), qr/^X=1$/m, 'env zeigt die Shell-Umgebung' );
like( sh('free -m'), qr/\A\s+total\s+used/, 'free -m' );

# sed mit Adressen (Zeilen, Bereiche, Muster, !) vor s und d
$state->{srv}{files}{'/etc/c.conf'} = "a\nb\nc\nd\ne\n";
sh(q{sed -i '2,3s/^/#/' /etc/c.conf});
is( $state->{srv}{files}{'/etc/c.conf'}, "a\n#b\n#c\nd\ne\n", 'sed 2,3s: nur der Bereich' );
sh(q{sed -i '/^d$/,$d' /etc/c.conf});
is( $state->{srv}{files}{'/etc/c.conf'}, "a\n#b\n#c\n", 'sed /re/,$d' );
sh(q{sed -i '1!s/#//' /etc/c.conf});
is( $state->{srv}{files}{'/etc/c.conf'}, "a\nb\nc\n", 'sed 1!s: alle ausser Zeile 1' );
sh(q{sed -i '/b/s/$/ x/g' /etc/c.conf});
is( $state->{srv}{files}{'/etc/c.conf'}, "a\nb x\nc\n", 'sed /re/s mit g' );
$state->{srv}{files}{'/etc/c.conf'} = "k=1\nk=1\n";
sh(q{sed -i '0,/k=1/s/k=1/k=2/' /etc/c.conf});
is( $state->{srv}{files}{'/etc/c.conf'}, "k=2\nk=1\n", 'sed 0,/re/: nur der erste Treffer' );

# Container: Systemdateien, Datenverzeichnis, psql
like( sh('docker exec app-db-1 cat /etc/resolv.conf'), qr/nameserver 127\.0\.0\.11/, 'Container: resolv.conf von Docker' );
like( sh('docker exec app-db-1 cat /etc/hosts'), qr/\A127\.0\.0\.1\tlocalhost/, 'Container: /etc/hosts' );
like( sh('docker exec app-db-1 ls /var/lib/postgres/data'), qr/^PG_VERSION$/m, 'Volume am falschen Pfad: alte Daten liegen dort' );
is( sh('docker exec app-db-1 ls /var/lib/postgresql/data | grep -c PG'), '1', 'am richtigen Pfad: frisch initialisiert' );
is( sh(q{docker exec app-db-1 psql -U postgres -c '\dt'}), 'Did not find any relations.', 'psql: leere Datenbank (Volume nicht am Datenpfad)' );
( $o, $ok ) = sh(q{docker exec app-db-1 psql -U postgres -c 'select count(*) from kunden'});
ok( !$ok && $o =~ /relation "kunden" does not exist/, '... Tabelle fehlt' );
$state->{srv}{files}{'/srv/app/compose.yaml'} =~ s{/var/lib/postgres/data}{/var/lib/postgresql/data};
sh('cd /srv/app && docker compose up -d');
like( sh(q{docker exec app-db-1 psql -U postgres -c 'select count(*) from kunden'}), qr/\b1204\b/, 'nach der Korrektur: Daten da' );

# Go-Vorlagen mit range
like( sh(q{docker inspect -f '{{range .Mounts}}{{.Name}} {{.Destination}}{{println}}{{end}}' app-db-1}), qr/\Aapp_pgdata \/var\/lib\/postgresql\/data\n?\z/,
    'inspect --format mit range und println' );
like( sh(q{docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' app-db-1}), qr/\Aapp_default \z/, 'range mit $k, $v' );
like( sh(q{docker inspect -f '{{json .State.Health}}' app-db-1}), qr/\Anull\z/, 'json eines fehlenden Felds' );
like( sh('docker stats --no-stream'), qr/app-db-1/, 'docker stats' );
like( sh('docker info'), qr/Server Version: 26\.1\.5/, 'docker info' );

my ( undef, undef, $gap ) = sh('ps aux; date; which nginx; md5sum /etc/a.conf; wc -c /etc/a.conf; docker info');
is( $gap, undef, 'keine Luecke der Simulation mehr bei diesen Befehlen' );

done_testing;
