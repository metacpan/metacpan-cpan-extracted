#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Shell-Hilfen des Linux-Simulators, die Modelle bei Webserver- und
# Zertifikatsaufgaben staendig nutzen. Behauptet wird: for-Schleifen
# laufen je Wort (auch mit Muster), grep -r durchsucht Verzeichnisse und nennt
# die Datei (Verweise nur mit -R), -l nennt nur Dateien; ln -s ziel verzeichnis/
# legt den Verweis im Verzeichnis an; eine Datei, die nur als Text im Zustand
# steht, hat unter content diesen Text (Regeln an neu geschriebenen Dateien).

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = { h => { type => 'linux', files => {
    '/etc/nginx/nginx.conf'           => "http {\n    ssl_protocols TLSv1 TLSv1.2;\n}\n",
    '/etc/nginx/sites-available/shop' => "server {\n    ssl_protocols TLSv1.1;\n}\n",
    '/etc/nginx/sites-enabled/shop'   => { link => '/etc/nginx/sites-available/shop' },
    '/etc/ssl/a.pem'                  => "A\n",
    '/etc/ssl/b.pem'                  => "B\n",
} } };
my $state;
sub fresh { $state = clone($start) }
sub sh { my ( $o, $ok ) = run_command( $state, 'h', $_[0] ); return wantarray ? ( $o, $ok ) : $o }

fresh();
is( sh('for f in /etc/ssl/*.pem; do echo "== $f"; cat $f; done'), "== /etc/ssl/a.pem\nA\n== /etc/ssl/b.pem\nB", 'for mit Muster: je Datei' );
is( sh('for x in 1 2; do echo ${x}; done; echo ende'), "1\n2\nende", 'for mit Liste, danach weiter' );

is( sh('grep -r ssl_protocols /etc/nginx/'),
    "/etc/nginx/nginx.conf:    ssl_protocols TLSv1 TLSv1.2;\n/etc/nginx/sites-available/shop:    ssl_protocols TLSv1.1;",
    'grep -r: Dateiname vorn, Verweise in sites-enabled uebergangen' );
like( sh('grep -R ssl_protocols /etc/nginx'), qr{/etc/nginx/sites-enabled/shop:}, 'grep -R folgt Verweisen' );
is( sh('grep -rl TLSv1.1 /etc/nginx'), '/etc/nginx/sites-available/shop', 'grep -l nennt die Datei' );
my ( $o, $ok ) = sh('grep -r gibtsnicht /etc/nginx');
ok( !$ok && $o eq '', 'kein Treffer: Exit 1, leer' );
like( sh('grep ssl /etc/nginx'), qr/Is a directory/, 'grep ohne -r auf ein Verzeichnis' );

sh('ln -s /etc/ssl/a.pem /etc/nginx/');
is( $state->{h}{files}{'/etc/nginx/a.pem'}{link}, '/etc/ssl/a.pem', 'ln -s ziel verzeichnis/' );

sh('echo neu > /etc/ssl/c.txt');
my ( $found, $v ) = get( $state, 'h', 'files', '/etc/ssl/c.txt', 'content' );
ok( $found && $v eq "neu\n", 'content einer reinen Text-Datei' );
( $found, $v ) = get( $state, 'h', 'files', '/etc/ssl/c.txt', 'mode' );
ok( !$found, '... mode gibt es dort nicht' );
done_testing;
