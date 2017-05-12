#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

MVC::Neaf->route( path => sub {
    my $req = shift;
    return { -content => $req->path_info };
}, path_info_regex => '.*a.*' );

my @ret = MVC::Neaf->run_test( { REQUEST_URI => '/path/foo' } );
is ($ret[0], 404, "No match = not found");

@ret = MVC::Neaf->run_test( { REQUEST_URI => '/path/bar' } );
is ($ret[0], 200, "Match = 200");
is ($ret[2], 'bar', "Match path_info round trip");

done_testing;
