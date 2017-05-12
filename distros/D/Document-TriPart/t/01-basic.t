#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

use Document::TriPart;

my ( $document, $file );

$document = Document::TriPart->read( \<<_END_ );
{}
---
_END_
ok( $document );
ok( $document->header );

TODO: {
    local $TODO = '...';
    $document = Document::TriPart->read( \<<_END_ );
{ a: 1 }
---
_END_
    ok( $document );
    ok( $document->header );
    cmp_deeply( $document->header, { qw/a 1/ } );
}

$document = Document::TriPart->read( \<<_END_ );
# vim: #
---
hello: world
---
This is the body
_END_

ok( $document );
is( $document->preamble, "# vim: #\n" );
cmp_deeply( $document->header, { qw/hello world/ } );
cmp_deeply( $document->body, "This is the body\n" );

$document = Document::TriPart->read_string( <<_END_ );
# vim: #
---
hello: world
---
This is the body
_END_

ok( $document );
is( $document->preamble, "# vim: #\n" );
cmp_deeply( $document->header, { qw/hello world/ } );
cmp_deeply( $document->body, "This is the body\n" );

$document->read_string( <<_END_ );
bye: world
---
A different body
_END_

ok( $document );
is( $document->preamble, undef);
cmp_deeply( $document->header, { qw/bye world/ } );
cmp_deeply( $document->body, "A different body\n" );

$document->read_string( <<_END_ );
Just a body
_END_

ok( $document );
is( $document->preamble, undef);
cmp_deeply( $document->header, {} );
cmp_deeply( $document->body, "Just a body\n" );

$document->header( { qw/alpha beta/ } );
is( $document->write_string, <<_END_ );
alpha: beta
---
Just a body
_END_

$document->preamble( \"Whatever" );
is( $document->write_string, <<_END_ );
Whatever
---
alpha: beta
---
Just a body
_END_

$document = Document::TriPart->new;
$document->header->{1} = 0;
is( $document->write_string, <<_END_ );
1: 0
---
_END_

$file = 't/assets/document';

open DOCUMENT, $file;
$document = Document::TriPart->read( \*DOCUMENT );
is( $document->preamble, "# vim: #\n" );
cmp_deeply( $document->header, { qw/hello world/ } );
cmp_deeply( $document->body, "This is the body\n" );

$document = Document::TriPart->read( $file );
is( $document->preamble, "# vim: #\n" );
cmp_deeply( $document->header, { qw/hello world/ } );
cmp_deeply( $document->body, "This is the body\n" );

$document = Document::TriPart->read( file => $file );
is( $document->preamble, "# vim: #\n" );
cmp_deeply( $document->header, { qw/hello world/ } );
cmp_deeply( $document->body, "This is the body\n" );

$document = Document::TriPart->read( \<<_END_ );
---
_END_
warning_is { $document->header } undef;

{
	local $Document::TriPart::TriPart = 0;

	$document = Document::TriPart->read( \<<_END_ );
hello: world
---
This is a body with '---'

Just before ---

---

Just after ---

Another --- for good measure
---

Last one
---
_END_
}

cmp_deeply( $document->body, <<_END_ );
This is a body with '---'

Just before ---

---

Just after ---

Another --- for good measure
---

Last one
---
_END_

done_testing;
