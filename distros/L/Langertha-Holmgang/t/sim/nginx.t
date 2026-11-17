#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );
use Langertha::Holmgang::Sim::Linux::Pki ();

# nginx auf dem Linux-Simulator.
# Behauptet wird: nginx -t meldet Fehler wie nginx; geladen ist, was beim
# letzten Start/reload galt (reload mit Fehler laesst die alte Konfiguration
# laufen, restart mit Fehler laesst nginx aus); Anfragen folgen listen,
# server_name, Location-Reihenfolge (=, ^~, Regex, Praefix), proxy_pass mit
# und ohne URI-Teil, Vorgaben und Vererbung von proxy_set_header/add_header
# (eine Ebene ersetzt alle hoeheren), client_max_body_size, Zeitlimits,
# WebSocket, try_files/alias, allow/deny, 444; Proben stehen nach jedem
# Befehl im Zustand.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $P = \&Langertha::Holmgang::Sim::Linux::Pki::pem;
my $CONF = <<'C';
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
}

http {
	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	ssl_protocols TLSv1.2 TLSv1.3;
	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;
	gzip on;
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
C
my $SITE = <<'S';
server {
    listen 80;
    server_name shop.example.com;
    add_header X-Frame-Options DENY;
    client_max_body_size 1m;

    location / {
        proxy_pass http://127.0.0.1:3000;
    }
    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
    }
    location /static/ {
        alias /srv/shop/assets/;
    }
    location ~* \.(css|js|png)$ {
        root /srv/shop/public;
    }
    location /admin/ {
        allow 10.20.0.0/24;
        deny all;
        proxy_pass http://127.0.0.1:3000;
    }
}
S
my $start = {
    web1 => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['10.20.0.31/24'] } },
        services => { nginx => { active => $T }, shop => { active => $T } },
        nginx => {},
        files => {
            '/etc/nginx/nginx.conf' => $CONF,
            '/etc/nginx/sites-available/shop' => $SITE,
            '/etc/nginx/sites-enabled/shop' => { link => '/etc/nginx/sites-available/shop' },
            '/srv/shop/assets/logo.svg' => "<svg/>\n",
            '/srv/shop/public/app.js' => "console.log(1)\n",
        },
        http => {
            '127.0.0.1:3000' => { service => 'shop', routes => [ { path => '/', echo => $T }, { path => '/slow/', echo => $T, delay => 90 } ] },
        },
    },
    client1 => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['10.20.0.50/24'] } },
        files => { '/etc/hosts' => "127.0.0.1 localhost\n10.20.0.31 shop.example.com shop2.example.com\n" },
        probes => { api => { url => 'http://shop.example.com/api/v1/items?a=1' } },
    },
    outside => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['192.0.2.77/24'] } },
        files => { '/etc/hosts' => "198.51.100.10 shop.example.com\n" },
        http => {},
    },
};
# outside erreicht web1 ueber eine oeffentliche Adresse
$start->{web1}{interfaces}{eth1} = { addr => ['198.51.100.10/24'] };

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ( $host, $cmd ) = @_;
    my ( $o, $ok ) = run_command( $state, $host, $cmd );
    return wantarray ? ( $o, $ok ) : $o;
}
sub put { my ( $host, $path, $text ) = @_; return write_file( $state, $host, $path, $text ) }
sub J { my ($t) = @_; return JSON::MaybeXS->new->decode($t) }
sub site_edit { my ( $from, $to ) = @_; my $s = $state->{web1}{files}{'/etc/nginx/sites-available/shop'}; $s =~ s/\Q$from\E/$to/ or die "kein $from"; put( 'web1', '/etc/nginx/sites-available/shop', $s ) }

# --- nginx -t, laden ----------------------------------------------------------
fresh();
my ( $o, $ok ) = sh( 'web1', 'nginx -t' );
ok( $ok, 'nginx -t: Debian-Konfiguration mit Site ist gueltig' ) or diag $o;
like( $o, qr/syntax is ok\nnginx: configuration file \/etc\/nginx\/nginx.conf test is successful\z/, '... Meldung wie nginx' );
ok( $state->{web1}{nginx}{loaded}{files}{'/etc/nginx/sites-enabled/shop'}, 'erster Befehl erfasst die geladene Konfiguration' );
is( $state->{client1}{probes}{api}{result}{status}, 200, 'Probe nach dem Befehl gerechnet' );
is( $state->{client1}{probes}{api}{result}{backend}{path}, '/v1/items?a=1', 'proxy_pass mit / ersetzt das Praefix der Location' );

site_edit( 'location / {', 'locaton / {' );
( $o, $ok ) = sh( 'web1', 'nginx -t' );
ok( !$ok, 'Tippfehler: nginx -t scheitert' );
like( $o, qr{\Anginx: \[emerg\] unknown directive "locaton" in /etc/nginx/sites-enabled/shop:7\nnginx: configuration file /etc/nginx/nginx.conf test failed\z}, '... mit Datei und Zeile' );
( $o, $ok ) = sh( 'web1', 'systemctl reload nginx' );
ok( !$ok, 'reload mit kaputter Konfiguration scheitert' );
ok( $state->{web1}{services}{nginx}{active}, '... nginx laeuft weiter' );
is( $state->{client1}{probes}{api}{result}{status}, 200, '... mit der alten Konfiguration' );
( $o, $ok ) = sh( 'web1', 'systemctl restart nginx' );
ok( !$ok && !$state->{web1}{services}{nginx}{active}, 'restart mit kaputter Konfiguration: nginx ist aus' );
like( $state->{client1}{probes}{api}{result}{error}, qr/\A\(7\) Failed to connect/, '... und die Seite weg' );
like( sh( 'web1', 'journalctl -u nginx -n 5' ), qr/unknown directive "locaton"/, 'Journal nennt den Fehler' );

fresh();
site_edit( "proxy_pass http://127.0.0.1:3000;\n    }\n    location /api/", "proxy_pass http://127.0.0.1:3000\n    }\n    location /api/" );
like( sh( 'web1', 'nginx -t' ), qr/unexpected "\}" in \/etc\/nginx\/sites-enabled\/shop:9/, 'fehlendes ; vor } wie nginx' );
fresh();
site_edit( 'location /api/ {', "location /api/ {\n        listen 8080;" );
like( sh( 'web1', 'nginx -t' ), qr/"listen" directive is not allowed here/, 'Kontext: listen in location' );
fresh();
put( 'web1', '/etc/nginx/sites-available/b', "server {\n    listen 80 default_server;\n}\nserver {\n    listen 80 default_server;\n}\n" );
sh( 'web1', 'ln -s /etc/nginx/sites-available/b /etc/nginx/sites-enabled/' );
ok( $state->{web1}{files}{'/etc/nginx/sites-enabled/b'}, 'ln -s ziel verzeichnis/ legt den Verweis im Verzeichnis an' );
like( sh( 'web1', 'nginx -t' ), qr/a duplicate default server for 0\.0\.0\.0:80 in \/etc\/nginx\/sites-enabled\/b:5/, 'doppelter default_server' );
fresh();
site_edit( 'proxy_pass http://127.0.0.1:3000/;', 'proxy_pass http://shopapp/;' );
like( sh( 'web1', 'nginx -t' ), qr/host not found in upstream "shopapp"/, 'unbekannter Upstream-Name' );
fresh();
site_edit( 'root /srv/shop/public;', "root /srv/shop/public;\n        proxy_pass http://127.0.0.1:3000/x;" );
like( sh( 'web1', 'nginx -t' ), qr/"proxy_pass" cannot have URI part in location given by regular expression/, 'URI-Teil in Regex-Location' );
fresh();
site_edit( 'add_header X-Frame-Options DENY;', 'add_header X-Frame-Options $frame;' );
like( sh( 'web1', 'nginx -t' ), qr/unknown "frame" variable/, 'unbekannte Variable' );

# --- Anfragen -----------------------------------------------------------------
fresh();
my $r = J( sh( 'client1', 'curl -s http://shop.example.com/x' ) );
is( $r->{headers}{host}, '127.0.0.1:3000', 'Vorgabe: Host ist $proxy_host' );
is( $r->{headers}{connection}, 'close', 'Vorgabe: Connection close' );
is( $r->{path}, '/x', 'proxy_pass ohne URI-Teil: Pfad unveraendert' );
like( sh( 'client1', 'curl -sI http://shop.example.com/x' ), qr/X-Frame-Options: DENY/, 'add_header der Server-Ebene' );
is( sh( 'client1', 'curl -s http://shop.example.com/static/logo.svg' ), '<svg/>', 'alias ersetzt das Praefix' );
is( sh( 'client1', 'curl -s http://shop.example.com/app.js' ), 'console.log(1)', 'Regex-Location fuer Statisches' );
like( sh( 'client1', 'curl -s -o /dev/null -w "%{http_code}" http://shop.example.com/api/export.js' ), qr/\A404\z/,
    'Regex-Location schluckt /api/*.js (Falle)' );
site_edit( 'location /api/ {', 'location ^~ /api/ {' );
sh( 'web1', 'nginx -s reload' );
is( J( sh( 'client1', 'curl -s http://shop.example.com/api/export.js' ) )->{path}, '/export.js', '^~ hat Vorrang vor Regex' );

fresh();
site_edit( "location /api/ {\n", "location /api/ {\n        proxy_set_header X-Forwarded-Proto \$scheme;\n" );
site_edit( "client_max_body_size 1m;", "client_max_body_size 1m;\n    proxy_set_header Host \$host;" );
sh( 'web1', 'systemctl reload nginx' );
$r = J( sh( 'client1', 'curl -s http://shop.example.com/api/a' ) );
is( $r->{headers}{'x-forwarded-proto'}, 'http', 'proxy_set_header der Location wirkt' );
is( $r->{headers}{host}, '127.0.0.1:3000', '... und ersetzt den Host der Server-Ebene (Vererbung wie nginx)' );
is( J( sh( 'client1', 'curl -s http://shop.example.com/b' ) )->{headers}{host}, 'shop.example.com', 'ohne eigene: Host der Server-Ebene' );

fresh();
site_edit( "location /api/ {\n", "location /api/ {\n        add_header Cache-Control no-store;\n" );
sh( 'web1', 'systemctl reload nginx' );
unlike( sh( 'client1', 'curl -sI http://shop.example.com/api/a' ), qr/X-Frame-Options/, 'add_header in location verdraengt die der Server-Ebene' );

fresh();
put( 'web1', '/srv/big.bin', '' );
$state->{web1}{files}{'/srv/big.bin'} = { content => '', size => '5M' };
like( sh( 'web1', 'curl -s -o /dev/null -w "%{http_code}" --data-binary @/srv/big.bin -H "Host: shop.example.com" http://127.0.0.1/upload' ), qr/\A413\z/, '5 MB ueber 1m: 413' );
like( sh( 'client1', 'curl -s -o /dev/null -w "%{http_code}" http://shop.example.com/slow/r' ), qr/\A504\z/, 'Backend langsamer als proxy_read_timeout: 504' );
site_edit( "location / {\n", "location /slow/ {\n        proxy_read_timeout 120s;\n        proxy_pass http://127.0.0.1:3000;\n    }\n    location / {\n" );
sh( 'web1', 'systemctl reload nginx' );
like( sh( 'client1', 'curl -s -o /dev/null -w "%{http_code}" http://shop.example.com/slow/r' ), qr/\A200\z/, '... mit hoeherem Zeitlimit 200' );

fresh();
like( sh( 'client1', 'curl -s -o /dev/null -w "%{http_code}" http://shop.example.com/admin/' ), qr/\A200\z/, '/admin aus dem LAN erlaubt' );
like( sh( 'outside', 'curl -s -o /dev/null -w "%{http_code}" http://shop.example.com/admin/' ), qr/\A403\z/, '... von aussen 403' );

fresh();
$r = J( sh( 'client1', 'curl -s -H "Upgrade: websocket" -H "Connection: Upgrade" http://shop.example.com/ws' ) );
ok( !exists $r->{headers}{upgrade}, 'Upgrade wird ohne Konfiguration nicht weitergereicht' );
site_edit( "location / {\n", "location /ws {\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade \$http_upgrade;\n        proxy_set_header Connection \"upgrade\";\n        proxy_pass http://127.0.0.1:3000;\n    }\n    location / {\n" );
sh( 'web1', 'systemctl reload nginx' );
$r = J( sh( 'client1', 'curl -s -H "Upgrade: websocket" -H "Connection: Upgrade" http://shop.example.com/ws' ) );
is( $r->{headers}{upgrade}, 'websocket', 'mit http_version 1.1 und Kopfzeilen: Upgrade kommt an' );

fresh();
site_edit( "location / {\n        proxy_pass http://127.0.0.1:3000;\n    }", "location / {\n        root /srv/spa;\n        try_files \$uri \$uri/ /index.html;\n    }" );
put( 'web1', '/srv/spa/index.html', "<app/>\n" );
sh( 'web1', 'systemctl reload nginx' );
is( sh( 'client1', 'curl -s http://shop.example.com/konto/123' ), '<app/>', 'try_files faellt auf /index.html zurueck' );

fresh();
put( 'web1', '/etc/nginx/conf.d/default.conf', "server {\n    listen 80 default_server;\n    server_name _;\n    return 444;\n}\n" );
sh( 'web1', 'systemctl reload nginx' );
( $o, $ok ) = sh( 'client1', 'curl -sS http://10.20.0.31/' );
is( $o, 'curl: (52) Empty reply from server', 'unbekannter Host: 444 = leere Antwort' );
is( J( sh( 'client1', 'curl -s http://shop.example.com/x' ) )->{path}, '/x', 'bekannter Host weiter beim Shop' );
like( sh( 'client1', 'curl -s http://shop2.example.com/x' ), qr/\A\z/, 'zweiter Name ohne server_name: Vorgabe-Server' );

# Upstream mit Ausfall und backup
fresh();
site_edit( 'proxy_pass http://127.0.0.1:3000/;', 'proxy_pass http://shopapp/;' );
my $s = $state->{web1}{files}{'/etc/nginx/sites-available/shop'};
put( 'web1', '/etc/nginx/sites-available/shop', "upstream shopapp {\n    server 127.0.0.1:3001;\n    server 127.0.0.1:3000 backup;\n}\n$s" );
sh( 'web1', 'systemctl reload nginx' );
is( $state->{client1}{probes}{api}{result}{backend}{path}, '/v1/items?a=1', 'erster Upstream-Server tot: backup antwortet' );
$state->{web1}{services}{shop}{active} = JSON::MaybeXS::false();
sh( 'web1', 'true' );
is( $state->{client1}{probes}{api}{result}{status}, 502, 'alle tot: 502' );

# Anfangszustand mit ungetesteter Datei (initial)
fresh();
$state->{web1}{nginx}{initial} = { '/etc/nginx/sites-enabled/shop' => $SITE };
$state->{web1}{files}{'/etc/nginx/sites-available/shop'} =~ s/proxy_pass http:\/\/127.0.0.1:3000\/;/proxy_pass http:\/\/127.0.0.1:3000\/ /;
sh( 'web1', 'true' );
is( $state->{client1}{probes}{api}{result}{status}, 200, 'initial: geladen ist der alte Stand, nicht die kaputte Datei' );
ok( !( sh( 'web1', 'nginx -t' ) )[1], '... nginx -t sieht die Datei' );

# Unterschiedliche Sockets: HTTP auf HTTPS-Port und umgekehrt
fresh();
like( sh( 'client1', 'curl -sS https://shop.example.com:80/' ), qr/\Acurl: \(35\) .*wrong version number\z/, 'https auf HTTP-Port: (35)' );
ok( !( sh( 'client1', 'nginx -t' ) )[1], 'nginx nur auf Geraeten mit nginx' );
done_testing;
