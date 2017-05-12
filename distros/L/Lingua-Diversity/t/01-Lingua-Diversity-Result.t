#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::Result' ) || print "Bail out!\n";
}

my $result = Lingua::Diversity::Result->new(
    'diversity' => 1,
    'variance'  => 0,
    'count'     => 1,
);

# Created objects are of the right class...
cmp_ok(
    ref( $result ), 'eq', 'Lingua::Diversity::Result',
    'is a Lingua::Diversity::Result'
);


