#!perl -w

use strict;
use Test::More tests => 12;
require HTTP::Headers::Fast;


my $h = HTTP::Headers::Fast->new;
is_deeply($h->psgi_flatten, []);

$h = HTTP::Headers::Fast->new(foo => "bar", foo => "baaaaz", Foo => "baz");
is_deeply($h->psgi_flatten, ['Foo','bar','Foo','baaaaz','Foo','baz']);
is_deeply($h->psgi_flatten_without_sort, ['Foo','bar','Foo','baaaaz','Foo','baz']);

$h = HTTP::Headers::Fast->new(foo => ["bar", "baz"]);
is_deeply($h->psgi_flatten, ['Foo','bar','Foo','baz']);

$h = HTTP::Headers::Fast->new(foo => 1, bar => 2, foo_bar => 3);
is_deeply($h->psgi_flatten, ['Bar','2','Foo','1','Foo-Bar','3']);


$h = HTTP::Headers::Fast->new(
    a => "foo\r\n\r\nevil body" ,
    b => "foo\015\012\015\012evil body" ,
    c => "foo\x0d\x0a\x0d\x0aevil body" ,
);
is_deeply($h->psgi_flatten, [
    'A', "fooevil body",
    'B', "fooevil body",
    'C', "fooevil body",
    ]);

$h = HTTP::Headers::Fast->new(
    "Foo\000Bar" => "baz",
    "Qux\177Quux" => "42"
);
is_deeply($h->psgi_flatten, [ "Foo\000Bar" => 'baz', "Qux\177Quux" => '42' ]);
is_deeply(+{@{$h->psgi_flatten_without_sort}}, +{ "Foo\000Bar" => 'baz', "Qux\177Quux" => '42' });

$h = HTTP::Headers::Fast->new(
    "X-LWS-I"  => "Bar\r\n  true",
    "X-LWS-II" => "Bar\r\n\t\ttrue"
);
is_deeply($h->psgi_flatten, [ 'X-LWS-I' => 'Bar true', 'X-LWS-II' => 'Bar true' ]);
is_deeply(+{@{$h->psgi_flatten_without_sort}}, +{ 'X-LWS-I' => 'Bar true', 'X-LWS-II' => 'Bar true' });

$h = HTTP::Headers::Fast->new(
    "X-CR-LF" => "Foo\nBar\rBaz"
);
is_deeply($h->psgi_flatten, [ 'X-CR-LF' => 'FooBarBaz' ]);
is_deeply($h->psgi_flatten_without_sort, [ 'X-CR-LF' => 'FooBarBaz' ]);
