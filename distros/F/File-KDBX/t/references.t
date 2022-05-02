#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX;
use Test::More;

my $kdbx = File::KDBX->new;
my $entry1 = $kdbx->add_entry(
    title       => 'Sun Valley Bank Inc.',
    username    => 'fred',
    password    => 'secr3t',
);
my $entry2 = $kdbx->add_entry(
    title       => 'Donut Shoppe',
    username    => 'freddy',
    password    => '1234',
    testcustom  => 'a custom string',
);
my $entry3 = $kdbx->add_entry(
    title       => 'Sun Clinic Inc.',
    username    => 'jerry',
    password    => 'password',
    mycustom    => 'this is another custom string',
);

for my $test (
    ['{REF:U@T:donut}', 'freddy'],
    ['U@T:donut', 'freddy'],
    [[U => T => 'donut'], 'freddy', 'A reference can be pre-parsed parameters'],

    ['{REF:U@T:sun inc}', 'fred'],
    ['{REF:U@T:"Sun Clinic Inc."}', 'jerry'],

    ['{REF:U@I:' . $entry2->id . '}', 'freddy', 'Resolve a field by UUID'],

    ['{REF:U@O:custom}', 'freddy'],
    ['{REF:U@O:"another custom"}', 'jerry'],

    ['{REF:U@T:donut meh}', undef],
    ['{REF:O@U:freddy}', undef],
) {
    my ($ref, $expected, $note) = @$test;
    $note //= "Reference: $ref";
    is $kdbx->resolve_reference(ref $ref eq 'ARRAY' ? @$ref : $ref), $expected, $note;
}

done_testing;
