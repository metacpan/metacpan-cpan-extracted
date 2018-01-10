#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'doc-tag-required' => qr/<html> tag is required/ ],
], [<DATA>] );

__DATA__
<!-- doc-tag-required -->
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P>This is my paragraph</P>
    </BODY>
