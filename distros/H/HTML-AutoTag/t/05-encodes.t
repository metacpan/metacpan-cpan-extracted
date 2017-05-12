#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 8;

use HTML::AutoTag;

my $auto = HTML::AutoTag->new();

is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo><bar baz="qux"></foo>',
    "encodes turned off by default";

$auto = HTML::AutoTag->new( encode => 1 );
is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo>&lt;bar baz=&quot;qux&quot;&gt;</foo>',
    "setting encode to true encodes default chars";

$auto = HTML::AutoTag->new( encode => 1, encodes => '' );
is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo>&lt;bar baz=&quot;qux&quot;&gt;</foo>',
    "setting encodes to '' with encode set to true encodes default";

$auto = HTML::AutoTag->new( encode => 1, encodes => undef );
is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo>&lt;bar baz=&quot;qux&quot;&gt;</foo>',
    "setting encodes to undef with encode set to true encodes default";

$auto = HTML::AutoTag->new( encodes => 0 );
is $auto->tag( tag => 'foo', cdata => '<bar baz="0">' ),
    '<foo><bar baz="&#48;"></foo>',
    "encodes turned on for character 0";

$auto = HTML::AutoTag->new( encodes => '<=' );
is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo>&lt;bar baz&#61;"qux"></foo>',
    "encodes turned on for specific chars";

$auto = HTML::AutoTag->new( encode => 0, encodes => '<=' );
is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo><bar baz="qux"></foo>',
    "encodes turned off when encode is 0";

$auto = HTML::AutoTag->new( encode => '', encodes => '<=' );
is $auto->tag( tag => 'foo', cdata => '<bar baz="qux">' ),
    '<foo><bar baz="qux"></foo>',
    "encodes turned off when encode is ''";
