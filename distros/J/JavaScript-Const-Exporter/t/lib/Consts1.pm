package Consts1;

use strict;
use warnings;

use Const::Exporter

    tag_a => [
        'foo'  => 1,
        '$bar' => 2,
        '@baz' => [qw/ a b c /],
        '%bo'  => { a => 1 },
    ],

    tag_b => [
        '$zoo'  => 3,
    ];

1;
