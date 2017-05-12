#!/usr/bin/env perl
# DMR 2013-09-24 convert orientiations from Gaussian into molecules
use HackaMol;
use Math::Vector::Real;

my @c = <DATA>;
my @atoms =
  map { HackaMol::Atom->new( Z => $_->[1], coords => [ V( @$_[ 3, 4, 5 ] ) ] ) }
  map { [split] } grep { /(\s+\d+){3}(\s+-*\d+\.\d+){3}/ } @c;

my $mol = HackaMol::Molecule->new( name => 'g09mol', atoms => [@atoms] );

$mol->print_xyz;

__DATA__
piece of some molecule:
      1          7           0        4.227008    0.846178    3.128973
      2          6           0        5.553504    1.594704    2.986010
      3          6           0        6.068622    1.272113    1.599010
...

