#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

my $capture;
my $file = __FILE__;

get '/foo' => sub {
    $capture = shift;
    +{-content => 42};
}, path_info_regex => '.*';

neaf->run_test( '/foo/bar' );

like $capture->endpoint_origin, qr/^$file:(\d+)$/, "Origin in this file";
note $capture->endpoint_origin;

done_testing;
