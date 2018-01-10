#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-nonrepeatable' => qr/\Q<title> is not repeatable, but already appeared at (3:9)/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
        <TITLE>As if one title isn't enough</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P>This is my paragraph</P>
    </BODY>
</HTML>
