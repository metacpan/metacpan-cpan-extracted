#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'attr-unknown-entity' => qr/Entity &numsefisk; is unknown/ ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="Testing unknown entity &numsefisk;">
    </BODY>
</HTML>
