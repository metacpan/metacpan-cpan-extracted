# Test private iterator primitives

use Test::More tests => 4;

BEGIN {
  use_ok( 'Geo::Gpx' );
}

my @ar1 = ( 1, 2, 3 );
my @ar2 = ( 4, 5, 6 );
my @ar3 = ( @ar1, @ar2 );

sub drain_iter {
  my $iter = shift;
  my @ar   = ();
  while ( my $el = $iter->() ) {
    push @ar, $el;
  }
  return @ar;
}

my @r1 = drain_iter( Geo::Gpx::_iterate_points( \@ar1 ) );

is_deeply( \@r1, \@ar1, '_iterate_points' );

my $i1 = Geo::Gpx::_iterate_points( \@ar1 );
my $i2 = Geo::Gpx::_iterate_points( \@ar2 );
my @r2 = drain_iter( Geo::Gpx::_iterate_iterators( $i1, $i2 ) );

is_deeply( \@r2, \@ar3, '_iterate_iterators' );

my $gpx = Geo::Gpx->new();    # Empty

my @r3 = drain_iter( $gpx->iterate_points() );

is( scalar( @r3 ), 0, 'empty iterator' );
