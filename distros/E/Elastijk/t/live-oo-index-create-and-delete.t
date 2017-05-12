#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}


use Elastijk;

my $es = Elastijk->new( host => "localhost", port => "9200" );
my $test_index_name = "test_index_$$";
my $res;

subtest "create an index with settings and mappings" => sub {
    # Check if the index exists
    $res = $es->exists( index => $test_index_name );
    ok !$res, "The index $test_index_name should not exist because we have not created it yet.";

    # Create an index with settings and mappings.
    $res = $es->put(
        index => $test_index_name,
        body => {
            settings => {
                index => {
                    number_of_shards => 2,
                    number_of_replicas => 0,
                }
            },
            mappings => {
                cafe => {
                    properties => {
                        name => { type => "string" },
                        address => { type => "string" }
                    }
                }
            }
        }
    );

    subtest "Check if the index ($test_index_name) we just created exists" => sub {
        ok $es->exists( index => $test_index_name );
    };

    subtest "Check if the type 'cafe' exists in the index ${test_index_name}, by specifying the name of the type." => sub {
        ok $es->exists( index => $test_index_name, type => "cafe" );
    };

    subtest "check if the type 'printer' does not exist in the index ${test_index_name}" => sub {
        ok !($es->exists( index => $test_index_name, type => "printer" ));
    };

    # Delete the index.
    $res = $es->delete( index => $test_index_name );

    # Check if the index exists
    $res = $es->exists( index => $test_index_name );
    ok !$res, "The index $test_index_name does not exist, because we just deleted it.";
};

done_testing;
