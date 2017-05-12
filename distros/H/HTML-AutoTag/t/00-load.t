#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 9;

use_ok 'HTML::AutoTag';

my $auto = new_ok 'HTML::AutoTag';

is $auto->tag( tag => 'foo' ),
    '<foo />',
    "tag with no attributes or children";

is $auto->tag( tag => 'foo', cdata => 'bar' ),
    '<foo>bar</foo>',
    "tag with one child";

is $auto->tag( tag => 'foo', attr => { class => 'baz' } ),
    '<foo class="baz" />',
    "tag with only attributes";

is $auto->tag( tag => 'foo', attr => { class => 'baz' }, cdata => 'bar' ),
    '<foo class="baz">bar</foo>',
    "tag with attributes and one child";

is $auto->tag( tag => 'foo', cdata => [qw(bar baz qux)] ),
    '<foo>bar</foo><foo>baz</foo><foo>qux</foo>',
    "tag with multiple children";

is $auto->tag( tag => 'foo', attr => { col => [1..3] }, cdata => [qw(one two three four)] ),
    '<foo col="1">one</foo><foo col="2">two</foo><foo col="3">three</foo><foo col="1">four</foo>',
    "tag with multiple children and rotating attributes";

is $auto->tag( tag => 'bar', cdata => { tag => 'foo', attr => { col => [1..3] }, cdata => [qw(one two three four)] } ),
    '<bar><foo col="1">one</foo><foo col="2">two</foo><foo col="3">three</foo><foo col="1">four</foo></bar>',
    "nested tag with multiple children and rotating attributes";
