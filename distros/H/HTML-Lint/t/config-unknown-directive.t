#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    # [ 'config-unknown-directive' => q{Set #1 (6:5) Unknown directive "bongo"} ],
    [ 'config-unknown-directive' => qr/Unknown directive "bongo"$/ ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Test stuff</title>
    </head>
    <body bgcolor="white">
        <!-- html-lint bongo: on -->
        <!-- html-lint all: off -->
        <!-- html-lint elem-img-sizes-missing: off -->
    </body>
</html>
