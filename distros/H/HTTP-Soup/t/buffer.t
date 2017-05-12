#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;


BEGIN {
    use_ok('HTTP::Soup');
}

sub main {
    test_buffer();
    return 0;
}


sub test_buffer {
    my $buffer = HTTP::Soup::Buffer->new(
        2, # copy
        "hello"
    );
    isa_ok($buffer, 'HTTP::Soup::Buffer');
    is($buffer->data, "hello", "Data");
    is($buffer->length, length("hello"), "Length");
}


exit main() unless caller;
