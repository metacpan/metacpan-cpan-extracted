use strict;
use warnings;

use Test::More;
use HTML::Restrict;

my $hr = HTML::Restrict->new(
    rules => {
        iframe => [
            qw( width height ),
            {
                src         => qr{^http://www\.youtube\.com},
                frameborder => qr{^(0|1)$},
            }
        ],
    },
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" frameborder="0" src="http://www.youtube.com/embed/9gKeRZM2Iyc"></iframe>'
    ),
    'eq',
    '<iframe width="560" height="315" frameborder="0" src="http://www.youtube.com/embed/9gKeRZM2Iyc"></iframe>',
    'all constraints pass',
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" src="http://www.hostile.com/" frameborder="0"></iframe>'
    ),
    'eq',
    '<iframe width="560" height="315" frameborder="0"></iframe>',
    'one constraint fails',
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" src="http://www.hostile.com/" frameborder="A"></iframe>'
    ),
    'eq',
    '<iframe width="560" height="315"></iframe>',
    'two constraints fail',
);

$hr = HTML::Restrict->new(
    rules => {
        iframe => [
            { src         => qr{^http://www\.youtube\.com} },
            { frameborder => qr{^(0|1)$} },
            { height      => qr{^315$} },
            { width       => qr{^560$} },
        ],
    },
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" frameborder="0" src="http://www.youtube.com/embed/9gKeRZM2Iyc"></iframe>'
    ),
    'eq',
    '<iframe src="http://www.youtube.com/embed/9gKeRZM2Iyc" frameborder="0" height="315" width="560"></iframe>',
    'possible to maintain order',
);

done_testing;
