use strict;
use Test::More tests => 1;
require HTTP::Headers::Fast;

my $h = HTTP::Headers::Fast->new(foo => "bar", foo => "baaaaz", Foo => "baz");
ok($h->as_string_without_sort(), "Foo: bar\nFoo: baaaaz\nFoo: baz\n");

