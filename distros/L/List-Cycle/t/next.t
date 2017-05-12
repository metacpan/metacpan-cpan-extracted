#!perl -T

use warnings;
use strict;

use Test::More tests => 8;

use List::Cycle;

my $cycle = List::Cycle->new( {vals=> [2112, 5150, 90125]} );
isa_ok( $cycle, 'List::Cycle' );

is( $cycle->next,  2112, q{We are the priests} );
is( $cycle->next,  5150, q{Why can't this be love} );
is( $cycle->next, 90125, q{You can fool yourself} );
is( $cycle->next,  2112, q{What can this strange device be?} );
is( $cycle->next,  5150, q{That's what dreams are made of} );
is( $cycle->next, 90125, q{You can cheat until you're blind} );
is( $cycle->next,  2112, q{You don't get something for nothing} );
