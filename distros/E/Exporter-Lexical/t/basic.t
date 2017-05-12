#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Exporter::Lexical ();

sub foo { 'foo' }

is(foo(), "foo");
{
    BEGIN { Exporter::Lexical::lexical_import(foo => sub { "FOO" }) }
    is(foo(), "FOO");
}
is(foo(), "foo");

done_testing;
