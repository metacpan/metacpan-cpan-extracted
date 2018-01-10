#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'attr-unknown' => qr/Unknown attribute "FOOD" for tag <P>/i ],
    [ 'attr-unknown' => qr/Unknown attribute "Yummy" for tag <I>/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P FOOD="Burrito" ALIGN=RIGHT>This is my paragraph about burritos</P>
        <I YUMMY="Spanish Rice">This is my paragraph about refried beans</I>
    </BODY>
</HTML>
