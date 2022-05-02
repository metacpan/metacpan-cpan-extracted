#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Safe;
use Test::Deep;
use Test::More;

my $secret = 'secret';

my @strings = (
    {
        value => 'classified',
    },
    {
        value => 'bar',
        meh   => 'ignored',
    },
    {
        value => '你好',
    },
);

my $safe = File::KDBX::Safe->new([@strings, \$secret]);
cmp_deeply \@strings, [
    {
        value => undef,
    },
    {
        value => undef,
        meh   => 'ignored',
    },
    {
        value => undef,
    },
], 'Encrypt strings in a safe' or diag explain \@strings;
is $secret, undef, 'Scalar was set to undef';

my $val = $safe->peek($strings[1]);
is $val, 'bar', 'Peek at a string';

$safe->unlock;
cmp_deeply \@strings, [
    {
        value => 'classified',
    },
    {
        value => 'bar',
        meh   => 'ignored',
    },
    {
        value => '你好',
    },
], 'Decrypt strings in a safe' or diag explain \@strings;
is $secret, 'secret', 'Scalar was set back to secret';

done_testing;
