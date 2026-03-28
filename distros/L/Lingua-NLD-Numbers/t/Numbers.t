#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::NLD::Numbers');
    $tests++;
}

my $obj = Lingua::NLD::Numbers->new();
ok(ref $obj, 'constructor returns object');
$tests++;

my $result = $obj->parse(42);
ok(defined $result && length $result, 'parse(42) returns text');
$tests++;

done_testing($tests);
