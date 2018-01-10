#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-unopened' => qr/<\/p> with no opening <P>/i ],
], [<DATA>] );

__DATA__
<HTML> <!-- for elem-unopened -->
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        This is my paragraph</P>
    </BODY>
</HTML>
