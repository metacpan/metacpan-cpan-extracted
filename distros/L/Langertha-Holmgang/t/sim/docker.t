#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command clone need_parts );

BEGIN {
  my $why = need_parts(qw( Docker Http ));
  plan skip_all => $why if $why;
}

# Docker Compose auf einem simulierten Server. Behauptet wird je
# Fallstrick: die wirksame Konfiguration (Interpolation aus .env, $$), was up
# neu erzeugt und was nicht, dass restart Aenderungen nicht uebernimmt, dass
# down -v Daten loescht, Portkonflikte, Warten auf Gesundheit, Wettlauf beim
# Start, Netze und Namen, Bind-Mount-Rechte — und dass Lesen nichts aendert.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $COMPOSE = <<'Y';
services:
  db:
    image: postgres:16.4
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
    networks: [backend]
  api:
    image: registry.example.com/shop/api:2.4.1
    environment:
      DB_HOST: db
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "127.0.0.1:8080:8080"
    restart: unless-stopped
    networks: [backend]
volumes:
  pgdata:
networks:
  backend:
Y

my $API = {
    listens => [8080], user => '1000', tools => [qw( wget sh )],
    needs => [
        { env => 'DB_PASSWORD', log => ['fatal: DB_PASSWORD not set'] },
        { connect => '${DB_HOST}:5432', log => ['fatal: dial tcp ${DB_HOST}:5432: connect: connection refused'] },
        { equals => [ '${DB_PASSWORD}', '${peer:POSTGRES_PASSWORD}' ], log => ['fatal: password authentication failed for user "shop"'] },
    ],
    logs => ['listening on :8080'],
    http => { routes => [ { path => '/health', body => "ok\n" }, { path => '/', body => "shop api\n" } ] },
};
my $start = {
    srv => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['10.30.0.10/24'] } },
        files => {
            '/srv/shop/compose.yaml' => $COMPOSE,
            '/srv/shop/.env'         => "DB_PASSWORD='s3cr\$t'\n",
        },
        docker => {
            projects => { shop => { dir => '/srv/shop' } },
            images => {
                'postgres:16.4' => { listens => [5432], user => '999', warmup => 1, data_path => '/var/lib/postgresql/data',
                    tools => ['pg_isready'], needs => [ { env => 'POSTGRES_PASSWORD', log => ['Error: Database is uninitialized and superuser password is not specified.'] } ],
                    logs => ['database system is ready to accept connections'] },
                'registry.example.com/shop/api:2.4.1' => $API,
            },
            registry => { 'registry.example.com/shop/api:2.5.0' => $API },
            volumes => { shop_pgdata => { data => 'kunden-2026' } },
            host_ports => { '0.0.0.0:80' => 'apache2' },
        },
    },
};
my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok ) = run_command( $state, 'srv', $cmd );
    return wantarray ? ( $o, $ok ) : $o;
}
sub C { $state->{srv}{docker}{containers}{ $_[0] } }

# --- Anfangszustand und Lesen --------------------------------------------------
fresh();
my ( $o, $ok ) = sh('cd /srv/shop && docker compose ps');
ok( $ok, 'compose ps im Projektverzeichnis' );
like( $o, qr/shop-db-1 .*Up 2 hours \(healthy\)/, 'db laeuft und ist gesund (aus den Dateien abgeleitet)' );
like( $o, qr/shop-api-1 .*127\.0\.0\.1:8080->8080\/tcp/, 'api mit Port' );
is( C('shop-db-1')->{data}, 'kunden-2026', 'db sieht die Daten des Volumes' );
is( C('shop-api-1')->{config}{environment}{DB_PASSWORD}, 's3cr$t', ".env: einfache Anfuehrungszeichen woertlich" );
my $snap = clone($state);
sh('docker compose -f /srv/shop/compose.yaml config; docker ps -a; docker compose -p shop logs api; docker inspect shop-db-1');
is_deeply( $state, $snap, 'Lesen aendert nichts' );
( $o, $ok ) = sh('docker compose ps');
ok( !$ok, 'ohne Verzeichnis und ohne -p: keine Datei' );
like( $o, qr/no configuration file provided: not found/, '... mit der Meldung von Compose' );
like( sh('docker compose -p shop ps'), qr/shop-api-1/, '-p shop findet das Projekt ohne Datei (Labels)' );
like( sh('docker inspect -f "{{.State.Health.Status}}" shop-db-1'), qr/\Ahealthy\z/, 'inspect --format' );
# ohne --format wie Docker (Go): "Key": value, vier Leerzeichen
$o = sh('docker inspect shop-db-1');
like( $o, qr/\A\[\n    \{\n        "/, 'inspect: Liste, vier Leerzeichen' ) or diag $o;
unlike( $o, qr/" :/, '... kein Leerzeichen vor dem Doppelpunkt' );
like( sh('curl -s http://127.0.0.1:8080/health'), qr/\Aok\z/, 'curl an den veroeffentlichten Port' );
like( sh('docker compose -f /srv/shop/compose.yaml exec api wget -qO- http://localhost:8080/health'), qr/ok/, 'exec wget im Container' );
like( sh('docker compose -f /srv/shop/compose.yaml exec api curl http://db:5432/'), qr/executable file not found/, 'curl fehlt im Image' );
is( sh('docker compose -f /srv/shop/compose.yaml exec db printenv POSTGRES_PASSWORD'), 's3cr$t', 'exec printenv' );
like( sh('docker-compose ps'), qr/command not found/, 'docker-compose (v1) gibt es nicht' );

# --- up erzeugt nur Geaendertes neu ----------------------------------------------
fresh();
sh(q{sed -i 's/api:2.4.1/api:2.5.0/' /srv/shop/compose.yaml});
is( C('shop-api-1')->{image}, 'registry.example.com/shop/api:2.4.1', 'nur Datei: laeuft noch das alte Image' );
( $o, $ok ) = sh('cd /srv/shop && docker compose up -d');
ok( $ok, 'up -d' ) or diag $o;
like( $o, qr/api Pulling.*api Pulled/s, 'zieht das neue Image' );
like( $o, qr/Container shop-api-1  Recreate/, 'api neu erzeugt' );
like( $o, qr/Container shop-db-1  Running/, 'db bleibt' );
is( C('shop-db-1')->{seq}, $snap->{srv}{docker}{containers}{'shop-db-1'}{seq}, 'db nicht neu erzeugt' );
is( C('shop-db-1')->{restarts}, 0, 'db nicht neu gestartet' );
is( C('shop-api-1')->{status}, 'running', 'api laeuft' );

fresh();
sh(q{sed -i 's/api:2.4.1/api:2.5.0/' /srv/shop/compose.yaml});
sh('cd /srv/shop && docker compose restart api');
is( C('shop-api-1')->{image}, 'registry.example.com/shop/api:2.4.1', 'restart uebernimmt die Datei nicht' );
is( C('shop-api-1')->{restarts}, 1, '... zaehlt aber einen Neustart' );

fresh();
sh('cd /srv/shop && docker compose down && docker compose up -d');
isnt( C('shop-db-1')->{seq}, $snap->{srv}{docker}{containers}{'shop-db-1'}{seq}, 'down+up erzeugt auch db neu' );
is( C('shop-db-1')->{data}, 'kunden-2026', '... Daten bleiben im Volume' );
fresh();
sh('cd /srv/shop && docker compose down -v && docker compose up -d');
is( C('shop-db-1')->{data}, 'leer', 'down -v loescht die Daten' );
ok( !$state->{srv}{docker}{volumes}{shop_pgdata}{data} || $state->{srv}{docker}{volumes}{shop_pgdata}{data} eq 'leer', '... Volume neu und leer' );

fresh();
sh('cd /srv/shop && docker compose up -d --force-recreate api');
is( C('shop-db-1')->{seq}, $snap->{srv}{docker}{containers}{'shop-db-1'}{seq}, '--force-recreate api erzeugt die Abhaengigkeit db nicht neu (Compose v2)' );
isnt( C('shop-api-1')->{seq}, $snap->{srv}{docker}{containers}{'shop-api-1'}{seq}, '... nur api' );
sh('cd /srv/shop && docker compose up -d --force-recreate --always-recreate-deps api');
isnt( C('shop-db-1')->{seq}, $snap->{srv}{docker}{containers}{'shop-db-1'}{seq}, '--always-recreate-deps auch db' );

# --- Fehlerbilder ------------------------------------------------------------------
fresh();
sh(q{sed -i 's/api:2.4.1/api:2.5/' /srv/shop/compose.yaml});
( $o, $ok ) = sh('cd /srv/shop && docker compose up -d');
ok( !$ok, 'unbekannter Tag scheitert' );
like( $o, qr/manifest for registry\.example\.com\/shop\/api:2\.5 not found: manifest unknown/, '... manifest unknown' );

fresh();
sh(q{sed -i 's/127.0.0.1:8080:8080/80:8080/' /srv/shop/compose.yaml});
( $o, $ok ) = sh('cd /srv/shop && docker compose up -d');
ok( !$ok, 'Port 80 vom Host belegt' );
like( $o, qr/listen tcp4 0\.0\.0\.0:80: bind: address already in use/, '... Meldung von Docker' );
is( C('shop-api-1')->{status}, 'created', '... Container nur erzeugt' );
( $o, $ok ) = sh('cd /srv/shop && docker compose start api');
ok( !$ok, 'start meldet den Portkonflikt erneut (frueher still „Started")' );
like( $o, qr/address already in use/, '... mit der Meldung' );
( $o, $ok ) = sh('docker start shop-api-1');
ok( !$ok && $o =~ /failed to start containers: shop-api-1/, 'docker start ebenso' );
like( sh(q{docker ps -a --filter "name=shop-api" --format 'table {{.Names}}\t{{.Status}}'}), qr/\ANAMES\tSTATUS\nshop-api-1\tCreated\z/,
    'docker ps --filter name= und --format table' );
like( sh(q{cd /srv/shop && docker compose ps -a --format '{{.Name}} {{.State}}'}), qr/shop-api-1 created/, 'compose ps --format' );
like( sh(q{docker inspect -f '{{.State.Status}} {{.State.Paused}} {{json .NetworkSettings.Ports}}' shop-db-1}), qr/\Arunning false \{\}\z/,
    'inspect: Paused und Ports (db veroeffentlicht nichts)' );
unlike( sh('docker compose -f /srv/shop/compose.yaml config'), qr/perl|Boolean/, 'config ohne Perl-Objekte' );

fresh();
$state->{srv}{files}{'/srv/shop/.env'} = "DB_PASSWORD=s3cr\$t\n";
( $o, $ok ) = sh('cd /srv/shop && docker compose up -d --force-recreate');
unlike( $o, qr/variable is not set/, 'ohne Anfuehrungszeichen: $t wird still ersetzt (keine Warnung)' );
is( C('shop-db-1')->{config}{environment}{POSTGRES_PASSWORD}, 's3cr', '... Passwort abgeschnitten' );

fresh();
$state->{srv}{files}{'/srv/shop/.env'} = "DB_PASSWORD=\n";
sh('cd /srv/shop && docker compose up -d --force-recreate');
is( C('shop-db-1')->{status}, 'exited', 'db ohne Passwort beendet' );
like( sh('docker logs shop-db-1'), qr/superuser password is not specified/, '... Log sagt warum' );
like( sh('cd /srv/shop && docker compose up -d'), qr/dependency failed to start: container shop-db-1/, 'api wartet vergeblich auf gesunde db' );

# --- Wettlauf ohne service_healthy ------------------------------------------------
fresh();
my $plain = $COMPOSE =~ s/    depends_on:\n      db:\n        condition: service_healthy\n/    depends_on: [db]\n/r;
$plain =~ s/    restart: unless-stopped\n//;
$state->{srv}{files}{'/srv/shop/compose.yaml'} = $plain;
sh('cd /srv/shop && docker compose up -d --force-recreate');
is( C('shop-api-1')->{status}, 'exited', 'ohne Warten und ohne Neustart-Regel: api stirbt beim gemeinsamen Start' );
sh('cd /srv/shop && docker compose up -d');
is( C('shop-api-1')->{status}, 'running', 'zweiter up: db laeuft schon, api startet' );

# --- Netze ------------------------------------------------------------------------
fresh();
( my $nonet = $COMPOSE ) =~ s/(  api:\n(?:.*\n)*?)    networks: \[backend\]\n/$1/;
$state->{srv}{files}{'/srv/shop/compose.yaml'} = $nonet;
sh('cd /srv/shop && docker compose up -d');
is( C('shop-api-1')->{status}, 'restarting', 'api im default-Netz erreicht db nicht' );
like( sh('docker logs --tail 1 shop-api-1'), qr/dial tcp db:5432/, '... Log nennt den Namen' );

# --- YAML und Pruefung -----------------------------------------------------------
fresh();
$state->{srv}{files}{'/srv/shop/compose.yaml'} =~ s/    environment:\n      DB_HOST: db/    environment:\n     DB_HOST: db/;
( $o, $ok ) = sh('docker compose -f /srv/shop/compose.yaml config -q');
ok( !$ok, 'kaputte Einrueckung' );
like( $o, qr/\Ayaml: line \d+: /, '... YAML-Fehler mit Zeile' );
fresh();
$state->{srv}{files}{'/srv/shop/compose.yaml'} =~ s/    restart:/    restrat:/;
like( sh('docker compose -f /srv/shop/compose.yaml config'), qr/services\.api additional properties 'restrat' not allowed/, 'Tippfehler im Schluessel' );

# --- Bind-Mount-Rechte ---------------------------------------------------------------
fresh();
my $bind = $COMPOSE =~ s{    restart: unless-stopped\n}{    restart: unless-stopped\n    volumes:\n      - ./uploads:/data\n}r;
$state->{srv}{files}{'/srv/shop/compose.yaml'} = $bind;
push @{ $state->{srv}{docker}{images}{'registry.example.com/shop/api:2.4.1'}{needs} }, { writable => '/data', log => ['fatal: open /data/.probe: permission denied'] };
$state->{srv}{users} = { deploy => { uid => 1000, groups => ['deploy'] } };
$state->{srv}{groups} = { deploy => { gid => 1000 } };
sh('cd /srv/shop && docker compose up -d');
is( C('shop-api-1')->{status}, 'restarting', 'fehlendes Verzeichnis legt Docker als root an: api darf nicht schreiben' );
is( $state->{srv}{dirs}{'/srv/shop/uploads'}{owner}, 'root', '... Verzeichnis gehoert root' );
sh('chown 1000:1000 /srv/shop/uploads; chown deploy:deploy /srv/shop/uploads; cd /srv/shop && docker compose restart api');
is( C('shop-api-1')->{status}, 'running', 'nach chown laeuft api' );

# --- Speichergrenze: OOM-Kill mit Exit 137 --------------------------
fresh();
push @{ $state->{srv}{docker}{images}{'registry.example.com/shop/api:2.4.1'}{needs} }, { memory => '600M', log => ['starting'] };
$state->{srv}{files}{'/srv/shop/compose.yaml'} =~ s/    restart: unless-stopped\n/    restart: unless-stopped\n    mem_limit: 256m\n/;
sh('true');
is( C('shop-api-1')->{status}, 'restarting', 'zu knappe Grenze: api startet staendig neu' );
like( sh(q{docker inspect -f '{{.State.ExitCode}} {{.State.OOMKilled}}' shop-api-1}), qr/\A137 true\z/, '... Exit 137, OOMKilled' );
$state->{srv}{files}{'/srv/shop/compose.yaml'} =~ s/mem_limit: 256m/mem_limit: 768m/;
sh('cd /srv/shop && docker compose up -d api');
is( C('shop-api-1')->{status}, 'running', 'mit 768m laeuft api' );
is( C('shop-api-1')->{mem_limit_bytes}, 768 * 1024 * 1024, '... Grenze in Bytes im Zustand' );

done_testing;
