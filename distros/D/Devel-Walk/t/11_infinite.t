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
my $bonk;
my $foo = { bonk=>\$bonk };
$foo->{foo} = $foo;
$foo->{again} = \$bonk;

walk( $foo, \&everything, '$foo' );
pass( "Successfully found loop" );

#use Data::Dump qw( pp );
#warn pp [ sort @everything ];

is_deeply( [ sort @everything ], [ 
  "\$\${\$foo->{again}}",
  "\$\${\$foo->{bonk}}",
  "\$foo",
  "\$foo->{again}",
  "\$foo->{bonk}",
  "\$foo->{foo}",
], "didn't recurse to deep" );
