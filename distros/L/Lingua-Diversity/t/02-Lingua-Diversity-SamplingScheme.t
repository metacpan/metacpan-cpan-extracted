#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::SamplingScheme' ) || print "Bail out!\n";
}

# Create a new sampling scheme...
my $sampling_scheme = Lingua::Diversity::SamplingScheme->new(
    'mode'              => 'random',
    'subsample_size'    => 100,
    'num_subsamples'    => 1000,
);

# Created objects are of the right class...
cmp_ok(
    ref( $sampling_scheme ), 'eq', 'Lingua::Diversity::SamplingScheme',
    'is a Lingua::Diversity::SamplingScheme'
);


