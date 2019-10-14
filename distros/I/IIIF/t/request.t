use strict;
use Test::More 0.98;
use IIIF::Request;

ok(IIIF::Request->new()->is_default, 'default request');

my @tests = (

    # region
    full    => 'full/max/0/default',
    square  => 'square/max/0/default',
    '125,15,120,140' => '125,15,120,140/max/0/default',
    'pct:41.6,7.5,40,70' => 'pct:41.6,7.5,40,70/max/0/default',

    # size
    max         => 'full/max/0/default',
    '^max'      => 'full/^max/0/default',
    'pct:01.20' => 'full/pct:1.2/0/default',
    '^pct:120'  => 'full/^pct:120/0/default',

    # rotation
    '!00.00' => 'full/max/!0/default',
    '90,'    => 'full/90,/0/default',
    '42'     => 'full/max/42/default',
    '!360'   => 'full/max/!0/default',
    '!721.2' => 'full/max/!1.2/default',

    # quality
    color    => 'full/max/0/color',
    gray     => 'full/max/0/gray',
    bitonal  => 'full/max/0/bitonal',

    # all together
    '125,15,120,140/90,/!345/gray.jpg' => '125,15,120,140/90,/!345/gray.jpg',
    '' => 'full/max/0/default',
);

while ( my ($req, $expect) = splice @tests, 0, 2 ) {
    is(IIIF::Request->new($req), $expect, "$req => $expect");
}

my @invalid = qw(
    0,0,0,0
    pct:0,0,101,101

    0,0
    pct:0,1
    pct:0
    pct:150
);

for (@invalid) {
    eval { IIIF::Request->new($_) };
    ok $@, "invalid: $_";
}

done_testing;
