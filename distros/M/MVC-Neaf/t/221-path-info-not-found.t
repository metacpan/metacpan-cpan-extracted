#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/foo' => sub { +{-content => 1} };
get '/bar' => sub { +{-content => 2} }, path_info_regex => '\d\d\d';

my ($status) = neaf->run_test( '/foo?bar=42' );
is $status, 200, "Found w/o info";

($status) = neaf->run_test( '/foo/bar?bar=42' );
is $status, 404, "Not found w/o info";

($status) = neaf->run_test( '/bar/42' );
is $status, 404, "Path info no match";

($status) = neaf->run_test( '/bar/137' );
is $status, 200, "Path info match";

done_testing;
