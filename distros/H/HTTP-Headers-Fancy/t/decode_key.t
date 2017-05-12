#!perl

use Test::More tests => 7;

use HTTP::Headers::Fancy qw(decode_key);

is decode_key('x')           => 'X';
is decode_key('Foo')         => 'Foo';
is decode_key('Foo-Bar')     => 'FooBar';
is decode_key('fOO-bAR')     => 'FooBar';
is decode_key('foo_bar')     => 'Foo_bar';
is decode_key('X-Foo')       => '-Foo';
is decode_key('a-b-c-d-e-f') => 'ABCDEF';

done_testing;
