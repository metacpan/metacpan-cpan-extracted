#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'attr-unknown' => qr/Unknown attribute "bongo" for tag <strong>/ ],
], [<DATA>] );

=pod

    HTML::Lint 2.02 and weblint, Red Hat EL 3

    This should result in no warnings:

    echo '<html><head><title>qwer</title></head><body><strong
    id="asdf">asdf</strong></body></html>' | weblint -
    - (1:45) Unknown attribute "id" for tag <strong>

    but it gives:

        - (1:45) Unknown attribute "id" for tag <strong>

    id is a core attribute in HTML4/XHTML1: http://www.w3.org/TR/html4/html40.txt

=cut

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <p>
        A test for <a href="http://code.google.com/p/html-lint/issues/detail?id=2">this bug</a>.
        </p>
        <p>
        <strong bongo="This">Bad</strong>
        <strong id="This">Bad</strong>
        </p>
    </BODY>
</HTML>
