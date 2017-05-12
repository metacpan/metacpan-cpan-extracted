#!perl
use strict;
use utf8;
use warnings;

use Test::More tests => 10;

use constant OLD => qq(AAABBBCCCDDDEEE);
use constant NEW => qq(AAABBB$/CCC$/DDD$/EEE);

use_ok('HTML::Tree');
use_ok('HTML::AsText::Fix');

isa_ok(
    my $tree =
        HTML::Tree->
            new_from_content(
                join('', <DATA>)
            ),
    'HTML::Element'
);

ok(
    $tree->as_text eq OLD,
    'init'
);

{
    ok(
        my $guard =
            HTML::AsText::Fix::object(
                $tree,
                zwsp_char => ''
            ),
        'object guard'
    );

    ok(
        $tree->as_text eq NEW,
        'object'
    );
}

ok($tree->as_text eq OLD, 'after object scope');

{
    ok(
        my $guard =
            HTML::AsText::Fix::global(
                zwsp_char => ''
            ),
        'global guard'
    );

    ok(
        $tree->as_text eq NEW,
        'global'
    );
}

ok(
    $tree->as_text eq OLD,
    'after global scope'
);

__DATA__
<html>
<head><title></title></head>
<body><p><span>AAA</span>BBB</p><h2>CCC</h2>DDD<br>EEE</body>
</html>
