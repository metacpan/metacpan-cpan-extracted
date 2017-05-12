#!perl
use strict;

use Test::More tests => 3;
use Test::Exception;

BEGIN { use_ok('Math::Random::Discrete'); }

my @weights;
my @values = qw/a b c d/;

dies_ok( sub { my $gen = Math::Random::Discrete->( \@weights, \@values ) },
    "no weights" );

@weights = (42);
dies_ok( sub { my $gen = Math::Random::Discrete->( \@weights, \@values ) },
    "mismatched weights and values" );
