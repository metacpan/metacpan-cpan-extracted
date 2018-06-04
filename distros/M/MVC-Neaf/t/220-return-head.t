#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/' => sub {
    return { -content => '', -headers => [ x_foo_bar => 42 ] };
};

my ($status, $head, $content) = neaf->run_test('/');

is $head->header("X-Foo-Bar"), 42, "Header made it";

done_testing;
