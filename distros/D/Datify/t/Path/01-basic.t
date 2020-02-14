#! /usr/bin/env perl

use strict;
use warnings;

# Proper testing requires a . at the end of the error message
use Carp 1.25;

use Test2::V0;
plan 8;

ok require Datify::Path, 'Required Datify::Path';

can_ok 'Datify::Path', qw(
    new
    get set
    pathify
);

my %hash = (
    alpha        => { a => 1, b => 2, c => 3 },
    empty_hash   => {},
    empty_list   => [],
    empty_string => '',
    num          => {
        10_000    => "ten thousand",
        10        => "ten",
        1_000_000 => "one million"
    },
    numbers      => [ '10000', '10', '1000000' ],
    nums         => [ 10_000, 10, 1_000_000 ],
    other        => 12,
    this         => { that => [ 1 .. 4, undef ] },
    "this/that"  => { "[1/0]" => undef },
    whatever     => { something => "else\nthat\tworks" },
);
my @array = map { $hash{$_} } sort keys %hash;

is(
    [ Datify::Path->pathify( \%hash ) ],
    [
        '/alpha/a = 1',
        '/alpha/b = 2',
        '/alpha/c = 3',
        '/empty_hash/',
        '/empty_list[0/0]',
        "/empty_string = ''",
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

is(
    [ Datify::Path->pathify( \@array ) ],
    [
        '[ 1/11]/a = 1',
        '[ 1/11]/b = 2',
        '[ 1/11]/c = 3',
        '[ 2/11]/',
        '[ 3/11][0/0]',
        "[ 4/11] = ''",
        '[ 5/11]/10 = ten',
        "[ 5/11]/10_000 = 'ten thousand'",
        "[ 5/11]/1_000_000 = 'one million'",
        '[ 6/11][1/3] = 10_000',
        '[ 6/11][2/3] = 10',
        '[ 6/11][3/3] = 1_000_000',
        '[ 7/11][1/3] = 10_000',
        '[ 7/11][2/3] = 10',
        '[ 7/11][3/3] = 1_000_000',
        '[ 8/11] = 12',
        '[ 9/11]/that[1/5] = 1',
        '[ 9/11]/that[2/5] = 2',
        '[ 9/11]/that[3/5] = 3',
        '[ 9/11]/that[4/5] = 4',
        '[ 9/11]/that[5/5]',
        "[10/11]/'[1/0]'",
        '[11/11]/something = "else\nthat\tworks"',
    ],
    'Array output looks sane'
);

is(
    [ Datify::Path->pathify( { %hash, hash => \%hash } ) ],
    [
        '/alpha/a = 1',
        '/alpha/b = 2',
        '/alpha/c = 3',
        '/empty_hash/',
        '/empty_list[0/0]',
        "/empty_string = ''",
        '/hash/alpha/a = 1',
        '/hash/alpha/b = 2',
        '/hash/alpha/c = 3',
        '/hash/empty_hash/',
        '/hash/empty_list[0/0]',
        "/hash/empty_string = ''",
        '/hash/num/10 = ten',
        "/hash/num/10_000 = 'ten thousand'",
        "/hash/num/1_000_000 = 'one million'",
        '/hash/numbers[1/3] = 10_000',
        '/hash/numbers[2/3] = 10',
        '/hash/numbers[3/3] = 1_000_000',
        '/hash/nums[1/3] = 10_000',
        '/hash/nums[2/3] = 10',
        '/hash/nums[3/3] = 1_000_000',
        '/hash/other = 12',
        '/hash/this/that[1/5] = 1',
        '/hash/this/that[2/5] = 2',
        '/hash/this/that[3/5] = 3',
        '/hash/this/that[4/5] = 4',
        '/hash/this/that[5/5]',
        "/hash/'this/that'/'[1/0]'",
        '/hash/whatever/something = "else\nthat\tworks"',
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

is(
    [ Datify::Path->pathify( [ @array, \@array ] ) ],
    [
        '[ 1/12]/a = 1',
        '[ 1/12]/b = 2',
        '[ 1/12]/c = 3',
        '[ 2/12]/',
        '[ 3/12][0/0]',
        "[ 4/12] = ''",
        '[ 5/12]/10 = ten',
        "[ 5/12]/10_000 = 'ten thousand'",
        "[ 5/12]/1_000_000 = 'one million'",
        '[ 6/12][1/3] = 10_000',
        '[ 6/12][2/3] = 10',
        '[ 6/12][3/3] = 1_000_000',
        '[ 7/12][1/3] = 10_000',
        '[ 7/12][2/3] = 10',
        '[ 7/12][3/3] = 1_000_000',
        '[ 8/12] = 12',
        '[ 9/12]/that[1/5] = 1',
        '[ 9/12]/that[2/5] = 2',
        '[ 9/12]/that[3/5] = 3',
        '[ 9/12]/that[4/5] = 4',
        '[ 9/12]/that[5/5]',
        "[10/12]/'[1/0]'",
        '[11/12]/something = "else\nthat\tworks"',
        '[12/12][ 1/11]/a = 1',
        '[12/12][ 1/11]/b = 2',
        '[12/12][ 1/11]/c = 3',
        '[12/12][ 2/11]/',
        '[12/12][ 3/11][0/0]',
        "[12/12][ 4/11] = ''",
        '[12/12][ 5/11]/10 = ten',
        "[12/12][ 5/11]/10_000 = 'ten thousand'",
        "[12/12][ 5/11]/1_000_000 = 'one million'",
        '[12/12][ 6/11][1/3] = 10_000',
        '[12/12][ 6/11][2/3] = 10',
        '[12/12][ 6/11][3/3] = 1_000_000',
        '[12/12][ 7/11][1/3] = 10_000',
        '[12/12][ 7/11][2/3] = 10',
        '[12/12][ 7/11][3/3] = 1_000_000',
        '[12/12][ 8/11] = 12',
        '[12/12][ 9/11]/that[1/5] = 1',
        '[12/12][ 9/11]/that[2/5] = 2',
        '[12/12][ 9/11]/that[3/5] = 3',
        '[12/12][ 9/11]/that[4/5] = 4',
        '[12/12][ 9/11]/that[5/5]',
        "[12/12][10/11]/'[1/0]'",
        '[12/12][11/11]/something = "else\nthat\tworks"',
    ],
    'Array output looks sane'
);

$hash{nested} = \%hash;
is(
    dies { [ Datify::Path->pathify( \%hash ) ] },
    sprintf( "Recursive structures not allowed at /nested at %s line %d.\n",
        __FILE__, __LINE__ - 2 ),
    'Nested hash dies',
);

push @array, \@array;
is(
    dies { [ Datify::Path->pathify( \@array ) ] },
    sprintf( "Recursive structures not allowed at [12/12] at %s line %d.\n",
        __FILE__, __LINE__ - 2 ),
    'Nested array dies',
);

### End of file ###
