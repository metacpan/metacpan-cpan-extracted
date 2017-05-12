#!perl -T

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
}

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Gettext ) ],
    logger  => sub { note shift },
);
$loc->expand_gettext->modifier_code(
    sub {
        my ( $value, $attribute ) = @_;
        if ( $attribute eq 'num' ) {
            # set the , between 3 digits
            while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
            # German number format
            $loc->language =~ m{\A de \b}xms
                and $value =~ tr{.,}{,.};
        }
        return $value;
    },
);

is
    $loc->__('{count :num} EUR', count => '12345678.90'),
    '12,345,678.90 EUR',
    'num en formatted';

$loc->language('de');
is
    $loc->__('{count :num} EUR', count => '12345678.90'),
    '12.345.678,90 EUR',
    'num de formatted';

$loc->expand_gettext->clear_modifier_code;
is
    $loc->__('{count :num} EUR', count => '12345678.90'),
    '12345678.90 EUR',
    'num no longer formatted';
