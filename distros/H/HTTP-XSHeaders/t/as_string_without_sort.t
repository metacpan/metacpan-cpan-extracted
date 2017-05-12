use strict;
use warnings;

use Test::More;
plan tests => 1;

use HTTP::XSHeaders;

my $h = HTTP::XSHeaders->new(foo => "bar", foo => "baaaaz", Foo => "baz");
ok($h->as_string_without_sort(), "Foo: bar\nFoo: baaaaz\nFoo: baz\n");
