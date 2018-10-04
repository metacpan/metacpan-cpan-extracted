#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::API::Error;

plan tests => 2;

subtest 'attributes'  => \&test_attributes;
subtest 'overloading' => \&test_overloading;

done_testing;

sub test_attributes {
    plan tests => 3;

    my $e = JSON::API::Error->new(
        {foo => 'bar', source => {pointer => '/forename'}, title => 'foo'});
    is $e->title => 'foo', 'title is foo';
    ok $e->can('source'), 'method `source` exists';
    ok !$e->can('foo'), 'method `foo` does not autovivify';
}

sub test_overloading {
    plan tests => 1;

    my $e = JSON::API::Error->new(
        {source => {pointer => '/forename'}, title => 'foo'});
    is "$e" => '/forename: foo', 'overloads as expected';
}
