#!perl

use strict;
use warnings;

use Test::More;
use Test::Number::Delta within => 0.001;
use Geo::Coordinates::ITM qw( ll_to_grid grid_to_ll );

my @case = (
  {
    name => 'Spire of Dublin',
    itm  => [ 715830, 734697 ],
    ll   => [ 53.3497939132163, -6.26024777285805 ]
  },
  {
    name => 'GPS station',
    itm  => [ 709885.081, 736167.699 ],
    ll   => [ 53.3642734370663, -6.34898734665306 ]
  },
);

plan tests => @case * 2;

for my $case ( @case ) {
  my $name = $case->{name};

  my @ll = grid_to_ll( @{ $case->{itm} } );
  delta_ok [@ll], $case->{ll}, "$name: grid_to_ll";

  my @grid = ll_to_grid( @{ $case->{ll} } );
  delta_ok [@grid], $case->{itm}, "$name: ll_to_grid";

}

# vim:ts=2:sw=2:et:ft=perl

