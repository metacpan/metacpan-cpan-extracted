#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use List::Breakdown 'breakdown';

our $VERSION = '0.20';

my @records = (
    "NEW CUSTOMER John O''Connor\r 2017-01-01",
    "RETURNING CUSTOMER\tXah Lee 2016-01-01",
    'CHECK ACCOUNT Pierre d\'Alun 2016-12-01',
    'RETURNING CUSTOMER Aaron Carter 2016-05-01',
);

my %buckets = (
    bad_whitespace     => qr/ [\r\t] /msx,
    apostrophes        => qr/ ' /msx,
    double_apostrophes => qr/ '' /msx,
    not_ascii          => qr/ [^[:ascii:]] /msx,
);

my %results = breakdown \%buckets, @records;

my %expected = (
    apostrophes => [
        "NEW CUSTOMER John O''Connor\r 2017-01-01",
        'CHECK ACCOUNT Pierre d\'Alun 2016-12-01',
    ],
    bad_whitespace => [
        "NEW CUSTOMER John O''Connor\r 2017-01-01",
        "RETURNING CUSTOMER\tXah Lee 2016-01-01",
    ],
    double_apostrophes => ["NEW CUSTOMER John O''Connor\r 2017-01-01"],
    not_ascii          => [],
);

is_deeply( \%results, \%expected, 'records' );
