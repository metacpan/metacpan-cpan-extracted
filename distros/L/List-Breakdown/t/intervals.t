#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use List::Breakdown 'breakdown';

our $VERSION = '0.22';

## no critic (ProhibitMagicNumbers,ProhibitLeadingZeros)
my @numbers = ( 1, 32, 3718.4, 0x56, 0777, 3.14, -5, 1.2e5 );
my $filters = {
    negative => [ undef, 0 ],
    positive => {
        small  => [ 0,   10 ],
        medium => [ 10,  100 ],
        large  => [ 100, undef ],
    },
};
my %filtered = breakdown $filters, @numbers;

my %expected = (
    negative => [ -5, ],
    positive => {
        large  => [ 3_718.4, 511, 120_000, ],
        medium => [ 32,      86, ],
        small  => [ 1,       3.14, ],
    },
);

is_deeply( \%filtered, \%expected, 'intervals' );
