#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok 'Locale::Utils::PlaceholderNamed' ;
}

my $obj = Locale::Utils::PlaceholderNamed->new(
    modifier_code => sub {
        my ($value, $attribute) = @_;
        if ( $attribute eq 'int' ) {
            return int $value;
        }
        return $value;
    },
);

eq_or_diff
    $obj->expand_named('{a} {b} {c:int} {d :int}'),
    '{a} {b} {c:int} {d :int}',
    'expand empty';
eq_or_diff
    $obj->expand_named(
        '{a} {b} {c:int} {d :int}',
        a => 'a',
        b => 2,
        c => '345678.90',
        d => 45678.90,
    ),
    'a 2 345678 45678',
    'expand hash';
