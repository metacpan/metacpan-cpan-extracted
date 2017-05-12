#!/usr/bin/perl

use 5.0014;

use strict;
use warnings;

use Test::More tests => 6;
use JSON::XS::Sugar qw(
    JSON_TRUE JSON_FALSE json_truth
);

is JSON_TRUE,  Types::Serialiser::true,  'JSON_TRUE';
is JSON_FALSE, Types::Serialiser::false, 'JSON_FALSE';

is json_truth 1,     Types::Serialiser::true,  'json_truth true';
is json_truth 0,     Types::Serialiser::false, 'json_truth 0';
is json_truth q[],   Types::Serialiser::false, 'json_false ""';
is json_truth undef, Types::Serialiser::false, 'json_false undef';
