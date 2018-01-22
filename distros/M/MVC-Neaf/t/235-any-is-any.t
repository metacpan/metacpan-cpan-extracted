#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

any '/foo' => sub {};

my $trace = neaf->get_routes( sub { 1 } );

is_deeply $trace
    , { '/foo' => { GET=>1, HEAD=>1, POST=>1, DELETE=>1, PUT=>1, PATCH=>1, } }
    , "Any really sets all known methods and no extra";

done_testing;
