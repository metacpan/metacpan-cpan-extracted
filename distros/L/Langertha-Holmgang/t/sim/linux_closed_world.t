#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Simulators;

# Linux-Simulator, geschlossene Welt im eigenen Netz (ADR 0012). Modelle proben
# gern Nachbaradressen (/dev/tcp, nc, wget, ping). Bisher war eine Adresse ohne
# Geraet im Zustand eine Luecke (TCP) bzw. immer erreichbar (ping). Behauptet
# wird: Im direkt angeschlossenen Netz gibt es nur, was der Zustand traegt oder
# nennt — eine andere Adresse dort antwortet "No route to host", ohne Luecke.
# Hinter dem Gateway und bei jeder Adresse, die der Zustand irgendwo nennt,
# bleibt alles wie bisher.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

sub world {
  return {
    app1 => {
      type       => 'linux',
      interfaces => { eth0 => { addr => ['10.40.0.71/24'], mtu => 1500, state => 'UP' } },
      routes     => [ { dst => 'default', via => '10.40.0.1', dev => 'eth0' }, { dst => '10.40.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.40.0.71' } ],
      files      => {
        '/etc/app/app.conf'    => "db_host = 10.40.0.50\n",
        '/usr/bin/nc'          => { mode => '0755', size => '40K', content => '' },
        '/etc/hosts'           => "127.0.0.1 localhost\n10.40.0.60 lager.example.internal\n",
      },
      services => { ssh => { active => 1 } },
    },
    db2 => {
      type       => 'linux',
      interfaces => { eth0 => { addr => ['10.40.0.72/24'], mtu => 1500, state => 'UP' } },
      routes     => [ { dst => '10.40.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.40.0.72' } ],
      services   => { ssh => { active => 1 } },
    },
  };
}
my $sims = Langertha::Holmgang::Simulators->new;
sub sh { return $sims->run_command( world(), 'app1', $_[0] ) }

# --- eine Adresse im eigenen Netz, die der Zustand nicht kennt: gibt es nicht ----------------
{
  my ( $o, $ok, $gap ) = sh('echo > /dev/tcp/10.40.0.7/22');
  ok( !$ok, '/dev/tcp auf eine unbekannte Nachbaradresse scheitert' );
  like( $o, qr{\Abash: connect: No route to host\nbash: /dev/tcp/10\.40\.0\.7/22: No route to host\z}, '… wie bash bei einem Host, der nicht antwortet' );
  ok( !defined $gap, '… ohne Luecke' );
  ( $o, $ok, $gap ) = sh('nc -zv 10.40.0.7 22');
  is( $o, 'nc: connect to 10.40.0.7 port 22 (tcp) failed: No route to host', 'nc ebenso' );
  ok( !$ok && !defined $gap, '… gescheitert, ohne Luecke' );
  ( $o, $ok, $gap ) = sh('wget -O- http://10.40.0.7/');
  like( $o, qr{Connecting to 10\.40\.0\.7 \(10\.40\.0\.7:80\)\.\.\. failed: No route to host\.\z}, 'wget ebenso' );
  ok( !$ok && !defined $gap, '… gescheitert, ohne Luecke' );
  ( $o, $ok, $gap ) = sh('ping -c 2 10.40.0.7');
  like( $o, qr{\APING 10\.40\.0\.7 .*\nFrom 10\.40\.0\.71 icmp_seq=1 Destination Host Unreachable\nFrom 10\.40\.0\.71 icmp_seq=2 Destination Host Unreachable\n\n--- 10\.40\.0\.7 ping statistics ---\n2 packets transmitted, 0 received, \+2 errors, 100% packet loss}s, 'ping: Destination Host Unreachable' );
  ok( !$ok && !defined $gap, '… gescheitert, ohne Luecke' );
}

# --- 10.40.0.7 ist nicht 10.40.0.71: die eigene Adresse macht die Nachbarin nicht bekannt ------
{
  my ( $o, $ok ) = sh('ping -c 1 10.40.0.71');
  ok( $ok, 'die eigene Adresse antwortet' );
}

# --- was der Zustand traegt, antwortet wie bisher ------------------------------------------------
{
  my ( $o, $ok, $gap ) = sh('nc -zv 10.40.0.72 22');
  is( $o, 'Connection to 10.40.0.72 22 port [tcp/ssh] succeeded!', 'ein Geraet des Zustands: offen' );
  ( $o, $ok, $gap ) = sh('ping -c 1 10.40.0.72');
  ok( $ok, '… und pingbar' );
}

# --- was der Zustand nennt, aber nicht traegt: die Welt weiss es nicht (wie bisher) --------------
for my $t (
  [ '10.40.0.50', 'Adresse aus einer Datei des Geraets' ],
  [ '10.40.0.1',  'das Gateway einer Route' ],
  [ 'lager.example.internal', 'Name aus /etc/hosts auf eine Adresse ohne Geraet' ],
) {
  my ( $o, $ok, $gap ) = sh("echo > /dev/tcp/$t->[0]/5432");
  ok( defined $gap, "TCP bleibt eine Luecke: $t->[1]" );
  ( $o, $ok, $gap ) = sh("ping -c 1 $t->[0]");
  ok( $ok, "… und ping antwortet: $t->[1]" );
}

# --- hinter dem Gateway: die Welt weiss es nicht (wie bisher) ------------------------------------
{
  my ( $o, $ok, $gap ) = sh('echo > /dev/tcp/192.0.2.9/443');
  ok( defined $gap, 'eine Adresse hinter dem Gateway bleibt eine Luecke' );
  ( $o, $ok ) = sh('ping -c 1 192.0.2.9');
  ok( $ok, '… und ping antwortet wie bisher' );
}

# --- ein Name, den niemand kennt: nicht aufloesbar (wie bisher) -----------------------------------
{
  my ( $o, $ok, $gap ) = sh('echo > /dev/tcp/gibtsnicht.example.internal/80');
  like( $o, qr/Name or service not known/, 'unbekannter Name' );
  ok( !defined $gap, '… ohne Luecke' );
}

# --- ein Geraet ohne eingetragene Routen: das eigene Netz gibt es trotzdem ------------------------
{
  my $s = world();
  delete $s->{$_}{routes} for qw( app1 db2 );
  my ( $o, $ok, $gap ) = $sims->run_command( $s, 'app1', 'nc -zv 10.40.0.72 22' );
  is( $o, 'Connection to 10.40.0.72 22 port [tcp/ssh] succeeded!', 'ohne routes: der Nachbar im eigenen Netz ist erreichbar' );
  ( $o, $ok, $gap ) = $sims->run_command( $s, 'app1', 'ping -c 1 10.40.0.72' );
  ok( $ok, '… und pingbar' );
  ( $o, $ok, $gap ) = $sims->run_command( $s, 'app1', 'nc -zv 10.40.0.7 22' );
  like( $o, qr/No route to host/, 'ohne routes: eine unbekannte Nachbaradresse gibt es nicht' );
  ( $o, $ok, $gap ) = $sims->run_command( $s, 'app1', 'echo > /dev/tcp/192.0.2.9/443' );
  ok( defined $gap, 'ohne routes: ausserhalb des eigenen Netzes weiss die Welt es nicht (Luecke)' );
}

done_testing;
