#!/usr/bin/env perl
# Langertha::Holmgang::Random, the generators' seeded source (ADR 0007).
# Claims: the algorithm is fixed -- the first values for two seeds are pinned
# (xoshiro128** seeded by splitmix32, checked against an independent
# implementation when written), so a change to it fails here and must raise the
# version of every generating suite; the same seed gives the same sequence, the
# global rand/srand does not move it; int stays in its bounds and reaches each
# value; pick and shuffle draw from the same source; bad seeds and bounds die.
use strict;
use warnings;
use Test::More;

use Langertha::Holmgang::Random;

sub rng { Langertha::Holmgang::Random->new( seed => $_[0] ) }

is_deeply( [ map { rng(4711)->next_u32 } 1 ], [373818564], 'seed 4711: first value pinned' );
{
  my $r = rng(4711);
  is_deeply( [ map { $r->next_u32 } 1 .. 4 ], [ 373818564, 3425125948, 3221024284, 1045470947 ], 'seed 4711: first four values pinned' );
  my $z = rng(0);
  is_deeply( [ map { $z->int( 1, 6 ) } 1 .. 10 ], [qw( 1 5 2 2 5 6 5 5 2 2 )], 'seed 0: ten dice pinned' );
}

{
  my ( $a1, $a2 ) = ( rng(99), rng(99) );
  srand(1);
  my @x = map { $a1->next_u32 } 1 .. 50;
  srand(2);
  rand() for 1 .. 10;
  my @y = map { $a2->next_u32 } 1 .. 50;
  is_deeply( \@x, \@y, 'same seed, same sequence; srand and rand do not move it' );
  isnt( join( ',', map { rng(1)->next_u32 } 1 ), join( ',', map { rng(2)->next_u32 } 1 ), 'neighbouring seeds start apart' );
}

{
  my $r = rng(7);
  my %seen;
  for ( 1 .. 2000 ) {
    my $v = $r->int( -3, 3 );
    $seen{$v}++;
  }
  is_deeply( [ sort { $a <=> $b } keys %seen ], [ -3 .. 3 ], 'int( -3, 3 ): every value, nothing outside' );
  ok( !grep( { $_ < 200 } values %seen ), '... none far below its share' );
  is( $r->int( 5, 5 ), 5, 'int with one value' );
  my $f = $r->float;
  ok( $f >= 0 && $f < 1, 'float in [0, 1)' );
  is( $r->int( 0, 4294967295 ) =~ /\A\d+\z/ ? 1 : 0, 1, 'the widest range' );
}

{
  my $r = rng(3);
  my @list = qw( a b c d e f g h );
  my @s = $r->shuffle(@list);
  is_deeply( [ sort @s ], \@list, 'shuffle: a permutation' );
  is_deeply( [ rng(3)->shuffle(@list) ], \@s, '... the same for the same seed' );
  my %p;
  $p{ $r->pick(@list) }++ for 1 .. 400;
  is( scalar keys %p, 8, 'pick reaches every element' );
}

for my $bad ( undef, -1, 1.5, 'x', 4294967296 ) {
  ok( !eval { rng($bad); 1 }, 'seed '.( $bad // 'undef' ).' refused' );
}
ok( !eval { rng(1)->int( 3, 2 ); 1 }, 'int: lower above upper refused' );
ok( !eval { rng(1)->int( 0.5, 2 ); 1 }, 'int: bounds must be integers' );
ok( !eval { rng(1)->pick(); 1 }, 'pick from nothing refused' );

done_testing;
