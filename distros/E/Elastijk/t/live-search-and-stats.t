#!/usr/bin/env perl

use strict;
use Test::More;
use Elastijk;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}

my @base_arg = (
    host => "127.0.0.1",
    port => "9200",
    method => "GET",
);

my @tests = (
    {},
    { command => "_stats" },

    { command => "_search",
          uri_param => { search_type => "count" },
          body => { query => { match_all => {} } } },
    { command => "_search",
      uri_param => { search_type => "count" },
      body => { query => { "match_all" => {} } }  },
);

for my $req_args (@tests) {
    my $args = { @base_arg, %$req_args };
    my ($status, $res) = Elastijk::request($args);
    is ref($res), 'HASH', substr(JSON::encode_json($res), 0, 60)."...";
}
done_testing;
