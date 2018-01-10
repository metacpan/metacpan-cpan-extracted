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
        <NOBR>NOBR is fine with me!</NOBR>
        <DONKY>
        <NOBR>But Donky is not</NOBR>
    </BODY>
</HTML>
