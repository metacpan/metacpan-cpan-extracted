#!/usr/bin/perl
use Test::More tests => 2;
use JavaScript::V8;
use utf8;
use strict;
use warnings;

my $context = JavaScript::V8::Context->new();

{
    my @expected = ( 'foo' );
    is_deeply($context->eval('["foo"];'), \@expected);
};

{
    my @expected = ( 'foo', 'bar', 'boo', 'far' );
    is_deeply($context->eval('["foo", "bar", "boo", "far"];'), \@expected);
};


done_testing;

