use strict;
use warnings;
use Test::More;

plan 'skip_all' => 'missing /dev/urandom'
    unless -e '/dev/urandom';
plan tests => 2;
require HTTP::Session::ID::Urandom;

is(length(HTTP::Session::ID::Urandom->generate_id(10)), 10, 'check length');

cmp_ok(HTTP::Session::ID::Urandom->generate_id(10), 'ne', HTTP::Session::ID::Urandom->generate_id(10), 'unique');

