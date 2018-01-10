#!perl

use strict;
use warnings;

use lib 't/';
use Util;

checkit( [
    [ 'attr-repeated' => qr/ALIGN attribute in <P> is repeated/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P ALIGN=LEFT ALIGN=RIGHT>This is my paragraph</P>
    </BODY>
</HTML>
