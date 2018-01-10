#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'config-unknown-value' => qr/Unknown value "14" for elem-img-sizes-missing directive$/ ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Test stuff</title>
    </head>
    <body bgcolor="white">
        <!-- html-lint elem-img-sizes-missing: true -->
        <!-- html-lint elem-img-sizes-missing: false -->
        <!-- html-lint elem-img-sizes-missing: on -->
        <!-- html-lint elem-img-sizes-missing: off -->
        <!-- html-lint elem-img-sizes-missing: 14 -->
        <!-- html-lint elem-img-sizes-missing: 0 -->
        <!-- html-lint elem-img-sizes-missing: 1 -->
    </body>
</html>
