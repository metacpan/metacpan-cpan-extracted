#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON;
use Elastijk;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}

my ($status, $res);
my $test_index_name = "test_$$";

## index exists
($status, $res) = Elastijk::request({ method => "HEAD", index  => $test_index_name });
is $status, "404", "$test_index_name missing";

## index creation
($status, $res) = Elastijk::request({
    method => "PUT",
    index  => $test_index_name,
    body   => {
        settings => {
            index => {
                number_of_shards => 1,
                number_of_replicas => 0
            }
        }
    }
});
is $status, "200";
ok( ($res->{ok} || $res->{acknowledged}) , encode_json($res)) if $res;

## index exists
($status, $res) = Elastijk::request({ method => "HEAD", index  => $test_index_name });
is $status, "200", "$test_index_name exists";
# diag encode_json($res);

## delete it.
($status, $res) = Elastijk::request({ method => "DELETE", index  => $test_index_name });
is $status, "200";
ok( ($res->{ok} || $res->{acknowledged}) , encode_json($res)) if $res;
# diag encode_json($res);

## index exists
($status, $res) = Elastijk::request({ method => "HEAD", index  => $test_index_name });
is $status, "404", "$test_index_name missing";

done_testing;

