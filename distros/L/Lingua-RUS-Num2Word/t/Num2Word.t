#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use 5.10.1;

use utf8;

use Test::More;

# Test names contain Cyrillic; encode TAP handles to avoid
# "Wide character in print" from Test2::Formatter::TAP.
binmode Test::More->builder->output,         ':encoding(UTF-8)';
binmode Test::More->builder->failure_output, ':encoding(UTF-8)';
binmode Test::More->builder->todo_output,    ':encoding(UTF-8)';

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::RUS::Num2Word');
    $tests++;
}

use Lingua::RUS::Num2Word            qw(rur_in_words get_string num2rus_ordinal);

# }}}

# {{{ rur_in_words


my $nw = [
    [
        8,
        'восемь рублей ноль копеек',
        '8.00 RUR',
    ],
    [
        '8.9',
        'восемь рублей девяносто копеек',
        '8.90 RUR',
    ],
    [
        999_888,
        'девятьсот девяносто девять тысяч восемьсот восемьдесят восемь рублей ноль копеек',
        '999 888 RUR',
    ],
    [
        -5,
        ' ноль копеек',
        'negative',
    ],
    [
        0,
        ' ноль копеек',
        '0 RUR',
    ],
    [
        undef,
        ' ноль копеек',
        'undef args',
    ],
];

for my $test (@{$nw}) {
    my $got = rur_in_words($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}



# }}}
# {{{ get_string

my $gs = [
    [
        [0, 0],
        'ноль копеек',
        '0',
    ],
    [
        [1, 1],
        'один рубль',
        '1',
    ],
    [
        [2, 2],
        'две тысячи',
        '2000',
    ],
    [
        [3, 3],
        'три миллиона',
        '3 000 000 000',
    ],
    [
        [3],
        'три',
        '3',
    ],
    [
        [undef, 3],
        undef,
        'undef value',
    ],
    [
        undef,
        undef,
        'undef args',
    ],
];

for my $test (@{$gs}) {
    my $got = get_string(@{$test->[0]});
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in RUS');
    $tests++;
}

# }}}
# {{{ num2rus_ordinal

my %ordinals = (
    0   => 'нулевой',
    1   => 'первый',
    2   => 'второй',
    3   => 'третий',
    4   => 'четвёртый',
    5   => 'пятый',
    6   => 'шестой',
    7   => 'седьмой',
    8   => 'восьмой',
    9   => 'девятый',
    10  => 'десятый',
    11  => 'одиннадцатый',
    12  => 'двенадцатый',
    13  => 'тринадцатый',
    14  => 'четырнадцатый',
    15  => 'пятнадцатый',
    16  => 'шестнадцатый',
    17  => 'семнадцатый',
    18  => 'восемнадцатый',
    19  => 'девятнадцатый',
    20  => 'двадцатый',
    21  => 'двадцать первый',
    22  => 'двадцать второй',
    23  => 'двадцать третий',
    30  => 'тридцатый',
    40  => 'сороковой',
    50  => 'пятидесятый',
    60  => 'шестидесятый',
    70  => 'семидесятый',
    80  => 'восьмидесятый',
    90  => 'девяностый',
    99  => 'девяносто девятый',
    100 => 'сотый',
    101 => 'сто первый',
    200 => 'двухсотый',
    300 => 'трёхсотый',
    1000 => 'тысячный',
    1001 => 'тысяча первый',
    2000 => 'два тысячный',
);

for my $num (sort { $a <=> $b } keys %ordinals) {
    my $got = num2rus_ordinal($num);
    is($got, $ordinals{$num}, "ordinal $num => $ordinals{$num}");
    $tests++;
}

# }}}

done_testing($tests);

__END__
