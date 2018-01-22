#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

get '/foo' => sub {};
get '/bar' => sub {}, public => 1, description => "Bar";

eval {
    get '/baz' => sub {}, public => 1;
};
like $@, qr/MVC::Neaf.*description/, "Description required if public";

my $trace = neaf->get_routes( sub { return $_[0]->{public} } );
is_deeply $trace,
    { '/bar' => { GET => 1, HEAD => 1 } },
    "Flag persists"
or diag explain $trace;

done_testing;
