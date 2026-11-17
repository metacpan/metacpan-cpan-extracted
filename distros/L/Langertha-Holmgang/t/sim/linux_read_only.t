#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: Lesebefehle aendern den Zustand nicht. Auf
# einem Rechner ohne nftables-Regeln legte "nft list ruleset" bisher einen
# leeren nft-Eintrag an — die Regel "sonst nichts geaendert" sah dann eine
# Aenderung, die es nicht gab.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $state = clone( { srv => { type => 'linux', interfaces => { eth0 => { addr => ['10.0.0.2/24'], state => 'UP' } } } } );
my $before = clone($state);
for my $cmd ( 'nft list ruleset', 'nft list tables', 'nft -a list ruleset' ) {
    my ( $o, $ok ) = run_command( $state, 'srv', $cmd );
    ok( $ok, "$cmd gelingt (leer)" );
}
is_deeply( $state, $before, 'Zustand unveraendert' );
my ( $o, $ok ) = run_command( $state, 'srv', 'nft add table inet filter' );
ok( $ok && exists $state->{srv}{nft}{'inet filter'}, 'Anlegen geht weiterhin' );

# ping mit Namen: aufgeloest wie getent (hosts, dann Nameserver), sonst "Name or service not known"
my $dns = clone( { srv => { type => 'linux',
    interfaces => { eth0 => { addr => ['10.0.0.2/24'], state => 'UP' } },
    routes => [ { dst => 'default', via => '10.0.0.1', dev => 'eth0' }, { dst => '10.0.0.0/24', dev => 'eth0', proto => 'kernel', scope => 'link', src => '10.0.0.2' } ],
    files => { '/etc/resolv.conf' => "nameserver 10.0.0.53\nsearch example.internal\n" },
    dns_servers => { '10.0.0.53' => { 'relay.example.internal' => '10.0.0.25' } } } } );
( $o, $ok ) = run_command( $dns, 'srv', 'ping -c 1 relay' );
ok( $ok, 'ping mit Kurzname ueber die Suchdomaene' );
like( $o, qr/\APING relay \(10\.0\.0\.25\)/, 'Kopfzeile mit Name und Adresse' );
( $o, $ok ) = run_command( $dns, 'srv', 'ping -c 1 fehlt.example.internal' );
ok( !$ok, 'unbekannter Name scheitert' );
like( $o, qr/Name or service not known/, 'wie iputils' );

done_testing;
