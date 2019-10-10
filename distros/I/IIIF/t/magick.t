use strict;
use Test::More 0.98;
use IIIF::Request;
use IIIF::Magick;

my @tests = (
    # region
    full      => [],
    '0,1,2,3' => [qw(-crop 2x3+0+1)],

    # size
    'pct:9.5' => [qw(-resize 9.5%)],
    '9,13'    => [qw(-resize 9x13!)],
    '^9,13'   => [qw(-resize 9x13!)],
    '!9,13'   => [qw(-resize 9x13)],
    '^!9,13'  => [qw(-resize 9x13)],
    '9,'      => [qw(-resize 9)],
    ',13'     => [qw(-resize x13)],

    # TODO: region followed by resize (rebase?)

    # rotation
    90      => [qw(-rotate 90)],
    '!0'    => [qw(-flop)],
    '!7'    => [qw(-flop -rotate 7 -background none)],
    '360'    => [],

    # quality
    color   => [],
    gray    => [qw(-colorspace Gray)],
    bitonal => [qw(-monochrome -colors 2)],
);

while ( my ($req, $args) = splice @tests, 0, 2 ) {
    $req = IIIF::Request->new($req);
    is_deeply([IIIF::Magick::args($req)], $args, "$req");
}

done_testing;
