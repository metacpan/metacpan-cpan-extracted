#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-unknown' => qr/unknown element <donky>/i ],
    [ 'elem-unclosed' => qr/<donky> at \(\d+:\d+\) is never closed/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P ALIGN=RIGHT>This is my paragraph</P>
        <DONKY>
        <IMG SRC="http://www.petdance.com/random/whizbang.jpg" BORDER=3 HEIGHT=4 WIDTH=921 ALT="whizbang!">
    </BODY>
</HTML>
