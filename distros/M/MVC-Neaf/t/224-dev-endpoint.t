#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my $capture;
my $file = __FILE__;

my $minline = __LINE__;
get '/foo' => sub {
    $capture = shift;
    +{-content => 42};
}, path_info_regex => '.*';
my $maxline = __LINE__;

neaf->run_test( '/foo/bar' );

like $capture->endpoint_origin, qr/^\Q$file\E line (\d+)$/, "Origin in this file";
note $capture->endpoint_origin;

# TODO also catch the line number - looks like `like` doen't do it for us...

done_testing;
