#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::RouterOS ();

# /ip pool used auf dem RouterOS-Simulator. Behauptet wird: das Menue leitet die
# belegten Adressen aus den Leases ab — eine Lease zaehlt, wenn ihre Adresse im Pool
# ihres DHCP-Servers liegt und sie nicht abgeschaltet ist (owner = Server, info =
# MAC); print, where und count-only gehen; aendern laesst es sich nicht, und es
# legt nichts im Zustand an.

my $R = 'Langertha::Holmgang::Sim::RouterOS';
my $dev = {
    type  => 'routeros',
    menus => {
        '/ip pool'        => [ { name => 'p1', ranges => '10.0.0.10-10.0.0.12' } ],
        '/ip dhcp-server' => [ { name => 'd1', interface => 'ether2', 'address-pool' => 'p1' } ],
        '/ip dhcp-server lease' => [
            { address => '10.0.0.5',  'mac-address' => 'AA:00:00:00:00:05', server => 'd1' },
            { address => '10.0.0.10', 'mac-address' => 'AA:00:00:00:00:10', server => 'd1', dynamic => 'yes' },
            { address => '10.0.0.11', 'mac-address' => 'AA:00:00:00:00:11', server => 'd1', dynamic => 'yes', disabled => 'yes' },
            { address => '10.0.0.12', 'mac-address' => 'AA:00:00:00:00:12', server => 'd1', dynamic => 'yes' },
        ],
    },
};
my $run = sub { my ( $o, $ok ) = $R->run( $dev, $_[0] ); return wantarray ? ( $o, $ok ) : $o };

is( $run->('/ip pool used print count-only'), 2, 'zwei belegt: ausserhalb des Pools und abgeschaltet zaehlen nicht' );
is( $run->('/ip pool used print where address=10.0.0.12'), ' 1    pool=p1 address=10.0.0.12 owner=d1 info=AA:00:00:00:00:12', 'print where, ohne Flags-Zeile' );
my ( $o, $ok ) = $run->('/ip pool used remove 0');
ok( !$ok, 'nicht aenderbar' );
like( $o, qr/bad command name remove/, '... wie RouterOS' );
$run->('/ip dhcp-server lease remove [find dynamic]');
is( $run->('/ip pool used print count-only'), 0, 'nach dem Loeschen der Leases frei' );
ok( !exists $dev->{menus}{'/ip pool used'}, 'legt nichts im Zustand an' );

done_testing;
