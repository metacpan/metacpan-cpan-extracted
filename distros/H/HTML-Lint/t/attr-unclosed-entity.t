#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'attr-unclosed-entity' => qr/Entity &#63; is missing its closing semicolon/ ],
    [ 'attr-unclosed-entity' => qr/Entity &ouml; is missing its closing semicolon/ ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="Unclosed entity at end of attr &#63">
    <a href="http://imotorhead.com/" title="Mot&ouml rhead rulez!">Mot&ouml;rhead</a>
    <a href="http://imotorhead.com/" title="Mot&ouml; rhead rulez!">Mot&ouml;rhead</a>
    </BODY>
</HTML>
