#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

sub foo { 'foo' }

is(foo(), "foo");
{
    use Foo;
    is(foo(), "FOO");
}
is(foo(), "foo");

done_testing;
