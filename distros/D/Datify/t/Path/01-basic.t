#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

ok require Datify::Path, 'Required Datify::Path';

can_ok 'Datify::Path', qw(
    _flatten
    pathify
    _pathify
);

my %hash = (
    this        => { that => [ 1 .. 4, undef ] },
    other       => 12,
    whatever    => { something => "else\nthat\tworks" },
    alhpa       => { a => 1, b => 2, c => 3 },
    "this/that" => { "[1/0]" => undef },
    empty_hash  => {},
    empty_list  => [],
    num         => {
        10_000    => "ten thousand",
        10        => "ten",
        1_000_000 => "one million"
    },
    nums        => [ 10_000, 10, 1_000_000 ],
    numbers     => [ '10000', '10', '1000000' ],
);
my @array = map { $hash{$_} } sort keys %hash;

is_deeply(
    [ Datify::Path->pathify( \%hash ) ],
    [
        '/alhpa/a = 1',
        '/alhpa/b = 2',
        '/alhpa/c = 3',
        '/empty_hash/',
        '/empty_list[0/0]',
        '/num/10 = ten',
        "/num/10_000 = 'ten thousand'",
        "/num/1_000_000 = 'one million'",
        '/numbers[1/3] = 10_000',
        '/numbers[2/3] = 10',
        '/numbers[3/3] = 1_000_000',
        '/nums[1/3] = 10_000',
        '/nums[2/3] = 10',
        '/nums[3/3] = 1_000_000',
        '/other = 12',
        '/this/that[1/5] = 1',
        '/this/that[2/5] = 2',
        '/this/that[3/5] = 3',
        '/this/that[4/5] = 4',
        '/this/that[5/5]',
        "/'this/that'/'[1/0]'",
        '/whatever/something = "else\nthat\tworks"',
    ],
    'Hash output looks sane'
);

is_deeply(
    [ Datify::Path->pathify( \@array ) ],
    [
        '[ 1/10]/a = 1',
        '[ 1/10]/b = 2',
        '[ 1/10]/c = 3',
        '[ 2/10]/',
        '[ 3/10][0/0]',
        '[ 4/10]/10 = ten',
        "[ 4/10]/10_000 = 'ten thousand'",
        "[ 4/10]/1_000_000 = 'one million'",
        '[ 5/10][1/3] = 10_000',
        '[ 5/10][2/3] = 10',
        '[ 5/10][3/3] = 1_000_000',
        '[ 6/10][1/3] = 10_000',
        '[ 6/10][2/3] = 10',
        '[ 6/10][3/3] = 1_000_000',
        '[ 7/10] = 12',
        '[ 8/10]/that[1/5] = 1',
        '[ 8/10]/that[2/5] = 2',
        '[ 8/10]/that[3/5] = 3',
        '[ 8/10]/that[4/5] = 4',
        '[ 8/10]/that[5/5]',
        "[ 9/10]/'[1/0]'",
        '[10/10]/something = "else\nthat\tworks"',
    ],
    'Array output looks sane'
);
