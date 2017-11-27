#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

my $capture;
get '/foo/' => sub {
    $capture = shift;
    +{};
}, -content => 'Done', path_info_regex => qr/(\w+)a(\w+)/;

my @ret;

@ret = neaf->run_test( '/foo' );
is $ret[0], 404, "no pinfo == not found";

@ret = neaf->run_test( '/foo/...bar' );
is $ret[0], 404, "regex covers ALL path info";

@ret = neaf->run_test( '/foo/bar' );
is $ret[0], 200, "found at last";
is $ret[2], 'Done', "Body as expected";

is $capture->path_info, 'bar', "path_info found";
is_deeply [$capture->path_info_split], ['b', 'r']
    , "path_info capture groups found";

done_testing;
