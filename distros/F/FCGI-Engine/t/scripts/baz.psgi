#!perl

use strict;
use warnings;

my $app = sub {
    my $env = shift;
    [ 200, [ 'Content-type' => 'text/plain' ], [ 'hello world' ]]
};