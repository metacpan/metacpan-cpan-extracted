#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-img-sizes-missing' => qr/\Q<IMG SRC="swedish-schwern.jpg"> tag has no HEIGHT and WIDTH attributes/i ],
    [ 'elem-img-sizes-missing' => qr/\Q<IMG SRC="bongo-bongo.jpg"> tag has no HEIGHT and WIDTH attributes/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P ALIGN=RIGHT>This is my paragraph</P>
        <IMG BORDER=3 HSPACE=12 SRC="swedish-schwern.jpg" ALT="Bork! Bork! Bork!" />
        <IMG BORDER="3" HSPACE="12" SRC="bongo-bongo.jpg" ALT="">
    </BODY>
</HTML>
