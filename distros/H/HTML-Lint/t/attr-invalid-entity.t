#!perl

use warnings;
use strict;

use lib 't/';
use Util;


# We used to have attr-invalid-entity if the entities had an invalid value, but we no longer do.

checkit( [
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="Testing invalid entity &#8675309;">
    <p style="color: &#xdeadbeef;"></p>
    </BODY>
</HTML>
