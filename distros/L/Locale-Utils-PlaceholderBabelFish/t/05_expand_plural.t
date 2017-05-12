#!perl -T

use strict;
use warnings;

use Test::More tests => 13;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok 'Locale::Utils::PlaceholderBabelFish';
}

my $obj = Locale::Utils::PlaceholderBabelFish->new;

# parameter types
eq_or_diff
    $obj->expand_babel_fish(
        '((#{count} s))',
        4234567.890,
    ),
    '4234567.89 s',
    'no strict, number';
eq_or_diff
    $obj->expand_babel_fish(
        '((#{count} s))',
        count => 4234567.890,
    ),
    '4234567.89 s',
    'no strict, hash';
eq_or_diff
    $obj->expand_babel_fish(
        '((#{count} s))',
        { count => 4234567.890 },
    ),
    '4234567.89 s',
    'no strict, hash_ref';

# broken count
eq_or_diff
    $obj->expand_babel_fish(
        '((s)):c1; ((s)):c2; ((s)):c3; ((s)):c4',
        c1 => undef,
        c2 => 'three',
        c3 => '4_234_567.890',
        c4 => 4234567.890,
    ),
    '((s)):c1; ((s)):c2; ((s)):c3; s',
    'no strict, broken count';

# plual selection
eq_or_diff
    $obj->expand_babel_fish(
        '((s|p)); ((s|p)):count0',
        count  => 1,
        count0 => 0,
    ),
    's; p',
    'no strict, plural';

# special zero
eq_or_diff
    $obj->expand_babel_fish(
        '((s|p)); ((=0 z|s|p))',
        0,
    ),
    'p; z',
    'no strict, special zero';

# unescape
eq_or_diff
    $obj->expand_babel_fish(
        '\(\(\#\{count\} s\|\#\{count\} p\)\)\:count',
        0,
    ),
    '((#{count} s|#{count} p)):count',
    'unescape';

# strict and modifier_code
$obj->is_strict(1);
$obj->modifier_code(
    sub {
        my ($value, $attributes) = @_;

        $attributes =~ m{ \b numf \b }xms
            or return $value;
        while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
        $value =~ tr{.,}{,.};

        return $value;
    },
);
eq_or_diff
    $obj->expand_babel_fish(
        '((#{count :numf} s|#{count :numf} p)); ((#{undef} s|#{undef} p)):undef',
        count => '4234567.890',
        undef => undef,
    ),
    '4.234.567,890 p; ((#{undef} s|#{undef} p)):undef',
    'strict, numf';

# strict, no modifier_code
$obj->clear_modifier_code;
eq_or_diff
    $obj->expand_babel_fish(
        '((#{count :numf} s|#{count :numf} p)); ((#{undef} s|#{undef} p)):undef',
        count => '4234567.890',
        undef => undef,
    ),
    '4234567.890 p; ((#{undef} s|#{undef} p)):undef',
    'strict, unknown numf';

# plural_code
$obj->plural_code(
    sub {
        my $n = shift;
        return 0 + (
            $n % 10 == 1
            && $n % 100 != 11 ? 0 : $n % 10 >= 2
            && $n % 10  <= 4
            && ( $n % 100 < 10 || $n % 100 >= 20 ) ? 1 : 2 # ru
        );
    }
);
eq_or_diff
    join(
        '; ',
        map {
            $obj->expand_babel_fish(
                '((#{count} s|#{count} p1|#{count} p2))',
                $_,
            );
        }
        0 .. 5
    ),
    '0 p2; 1 s; 2 p1; 3 p1; 4 p1; 5 p2',
    'strict, ru plural 0 .. 5';

# clear_plural_code
$obj->clear_plural_code;
eq_or_diff
    join( ', ', map { $obj->plural_code->($_) } 0 .. 5 ),
    '1, 0, 1, 1, 1, 1',
    'default plural_code 0 .. 5';
