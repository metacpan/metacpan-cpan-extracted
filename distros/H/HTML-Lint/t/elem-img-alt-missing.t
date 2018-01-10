#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-img-alt-missing' => qr/<IMG SRC="whizbang\.jpg"> does not have ALT text defined/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P ALIGN=RIGHT>This is my paragraph</P>
        <IMG SRC="whizbang.jpg" BORDER=3 HEIGHT=4 WIDTH=921 />
    </BODY>
</HTML>
