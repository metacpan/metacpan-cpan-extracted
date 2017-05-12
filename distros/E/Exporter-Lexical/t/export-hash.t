#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

package Foo {
    use Exporter::Lexical -exports => {
        foo => sub { "FOO" },
    };
    BEGIN { $INC{'Foo.pm'} = __FILE__ }
}

sub foo { 'foo' }

is(foo(), 'foo');
{
    use Foo;
    is(foo(), 'FOO');
}
is(foo(), 'foo');

done_testing;
