#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'elem-img-sizes-missing' => qr/\Q<img src="alpha.jpg"> tag has no HEIGHT and WIDTH attributes/i ],
    [ 'elem-img-alt-missing'   => qr/\Q<img src="alpha.jpg"> does not have ALT text defined/i ],

    [ 'elem-img-alt-missing'   => qr/\Q<img src="beta.jpg"> does not have ALT text defined/i ],

    # gamma.jpg will not error at all

    [ 'elem-img-alt-missing'   => qr/\Q<img src="delta.jpg"> does not have ALT text defined/i ],

    [ 'elem-img-sizes-missing' => qr/\Q<img src="epsilon.jpg"> tag has no HEIGHT and WIDTH attributes/i ],
    [ 'elem-img-alt-missing'   => qr/\Q<img src="epsilon.jpg"> does not have ALT text defined/i ],
    [ 'elem-unclosed'          => 'Set #1 (20:5) <gooble> at (13:9) is never closed' ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Test stuff</title>
    </head>
    <body bgcolor="white">
        <img src="alpha.jpg">

        <!-- html-lint elem-img-sizes-missing: off, attr-unknown: off -->
        <img src="beta.jpg" />

        <!-- html-lint all: off -->
        <img src="gamma.jpg" />
        <gooble darble="fungo" />

        <!-- html-lint elem-img-alt-missing: on -->
        <img src="delta.jpg">

        <!-- html-lint all: on -->
        <img src="epsilon.jpg">
    </body>
</html>
