#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok 'Locale::Utils::PlaceholderBabelFish';
}

my $obj = Locale::Utils::PlaceholderBabelFish->new(
    modifier_code => sub {
        my ($value, $attributes) = @_;
        if ( $attributes =~ m{ \b int \b }xms ) {
            return int $value;
        }
        return $value;
    },
);

eq_or_diff
    $obj->expand_babel_fish('#{a} #{b} #{c:int} #{d :int}'),
    '#{a} #{b} #{c:int} #{d :int}',
    'expand empty';
eq_or_diff
    $obj->expand_babel_fish(
        '#{a} #{b} #{c:int} #{d :int}',
        a => 'a',
        b => 2,
        c => '345678.90',
        d => 45678.90,
    ),
    'a 2 345678 45678',
    'expand hash';
