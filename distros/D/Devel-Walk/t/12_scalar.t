#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 2 );

use Devel::Walk;
use Storable qw( freeze );
use IO::File;

############################################
my @everything;
sub everything
{
    my( $loc ) = @_;
    push @everything, $loc;
    die "Recursing to deep" if 100 < @everything;
    return 1;
}

############################################
my $zonk = { hello=>1 };
my $bonk = { hello=>"hello" };
$bonk->{bonk} = \$zonk;
my $foo = \$bonk;

walk( $foo, \&everything, '$foo' );
pass( "Successful walk" );

use Data::Dump qw( pp );
#warn pp [ @everything ];

is_deeply( [ sort @everything ], [ sort
  "\$foo",
  "\$\${\$foo}",
  "\$\${\$foo}{hello}",
  "\$\${\$foo}{bonk}",
  "\$\${\$\${\$foo}{bonk}}",
  "\$\${\$\${\$foo}{bonk}}{hello}"
], "Top ref is a scalar" );
