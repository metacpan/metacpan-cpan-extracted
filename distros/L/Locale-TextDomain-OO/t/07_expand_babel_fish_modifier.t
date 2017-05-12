#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
}

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::BabelFish::Loc ) ],
    logger  => sub { note shift },
);
$loc->expand_babel_fish_loc->modifier_code(
    sub {
        my ( $value, $attribute ) = @_;
        if ( $attribute eq 'numf' ) {
            # set the , between 3 digits
            while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
            # German number format
            $value =~ tr{.,}{,.};
        }
        return $value;
    },
);

is
    $loc->loc_b('#{count :numf} EUR', '12345678.90'),
    '12.345.678,90 EUR',
    'num en formatted';

$loc->expand_babel_fish_loc->clear_modifier_code;
is
    $loc->loc_b('#{count :numf} EUR', count => '12345678.90'),
    '12345678.90 EUR',
    'num de formatted';

# overwrite to check initialization during translation
$loc->expand_babel_fish_loc->plural_code( sub { 0 } );
is
    $loc->loc_b('#{count :numf} ((singular|plural))', {count => '12345678.90'}),
    '12345678.90 plural',
    'plural';
is
    $loc->expand_babel_fish_loc->plural_code->(0),
    1,
    'check if english plural_code was used';

# mutiplural
is
    $loc->loc_b(
        '((singular1|plural1)); ((=0 #{count0} zero0|#{count0} singular0|#{count0} plural0)):count0; ((singular2|plural2)):count2',
        {
            count  => 1,
            count0 => 0,
            count2 => 2,
        },
    ),
    'singular1; 0 zero0; plural2',
    '3 plurals';
