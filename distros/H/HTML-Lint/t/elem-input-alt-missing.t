#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-input-alt-missing' => qr/<input name="dave" type="image"> does not have non-blank ALT text defined/i ],
    [ 'elem-input-alt-missing' => qr/<input name="empty-alt" type="image"> does not have non-blank ALT text defined/i ],
    [ 'elem-input-alt-missing' => qr/<input name="all-whitespace-alt" type="image"> does not have non-blank ALT text defined/i ],
    [ 'elem-input-alt-missing' => qr/<input name="" type="image"> does not have non-blank ALT text defined/i ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Test stuff</title>
    </head>
    <body bgcolor="#ffffff">
        <p align="right">
            This is my paragraph
        </p>
        <form method="post" action="foo.php">
            <input type="image" name="dave" />
            <input type="image" name="empty-alt" alt="" />
            <input name="all-whitespace-alt" type="image" alt="    " />
            <input type="image" />
            <input name="ok" type="image" alt="Blah blah" />
            <input type="text" name="bongo" />
        </form>
    </BODY>
</HTML>
