#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

use_ok 'HTML::AutoTag';

my $auto = HTML::AutoTag->new( indent => '    ' );
is $auto->tag( tag => 'foo' ),
    "<foo />\n",
    "correct indentation for closed tag";

is $auto->tag( tag => 'foo', cdata => 'bar' ),
    "<foo>bar</foo>\n",
    "correct indentation for tag with scalar cdata";

is $auto->tag( tag => 'foo', cdata => [qw(bar baz qux)] ),
    "<foo>bar</foo>
<foo>baz</foo>
<foo>qux</foo>
",
    "correct indentation for tag with array ref cdata";

is $auto->tag( tag => 'foo', cdata => { tag => 'bar' } ),
    "<foo>
    <bar />
</foo>
",
    "correct indentation for tag with empty tag cdata";

is $auto->tag( tag => 'bar', cdata => { tag => 'foo', attr => { col => [1..3] }, cdata => [qw(one two three four)] } ),
    '<bar>
    <foo col="1">one</foo>
    <foo col="2">two</foo>
    <foo col="3">three</foo>
    <foo col="1">four</foo>
</bar>
',
    "correct indentation for cdata as array ref";

is $auto->tag(
    tag => 'bar',
    cdata => { 
        tag => 'foo', 
        cdata => [ map { tag => 'bar', }, 1.. 4 ]
    }
), '<bar>
    <foo>
        <bar />
        <bar />
        <bar />
        <bar />
    </foo>
</bar>
',
    "correct indentation for cdata as hash ref";
