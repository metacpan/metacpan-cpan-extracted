#!perl -T

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
}

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Maketext ) ],
    logger  => sub { note shift },
);
$loc->expand_maketext->formatter_code(
    sub {
        my $value = shift;
        # set the , between 3 digits
        while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
        # German number format
        $loc->language =~ m{\A de \b}xms
            and $value =~ tr{.,}{,.};
        return $value;
    },
);

is
    $loc->maketext('[*,_1,EUR]', '12345678.90'),
    '12,345,678.90 EUR',
    'num en formatted';

$loc->language('de');
is
    $loc->maketext('[*,_1,EUR]', '12345678.90'),
    '12.345.678,90 EUR',
    'num de formatted';

$loc->expand_maketext->clear_formatter_code;
is
    $loc->maketext('[*,_1,EUR]', '12345678.90'),
    '12345678.90 EUR',
    'num no longer formatted';
