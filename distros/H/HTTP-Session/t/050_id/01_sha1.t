use strict;
use warnings;
use Test::More;

plan skip_all => "this test requires Digest::SHA1" unless eval "use Digest::SHA1;1;";
plan tests => 2;
require HTTP::Session::ID::SHA1;

is(length(HTTP::Session::ID::SHA1->generate_id(10)), 10, 'check length');

cmp_ok(HTTP::Session::ID::SHA1->generate_id(10), 'ne', HTTP::Session::ID::SHA1->generate_id(10), 'unique');

