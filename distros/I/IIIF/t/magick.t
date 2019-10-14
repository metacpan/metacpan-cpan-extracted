use strict;
use Test::More 0.98;
use IIIF::Request;
use IIIF::Magick qw(convert_command);

my @tests = (
    # region
    full      => [],
    'square' => [qw(-set option:distort:viewport 
        %[fx:w>h?h:w]x%[fx:w>h?h:w]+%[fx:w>h?(w-h)/2:0]+%[fx:w>h?0:(h-w)/2]
        -filter point -distort SRT 0 +repage)],
    '0,1,2,3' => [qw(-crop 2x3+0+1)],
    'pct:41.6,7.5,66.6,100' => [qw(-set page -%[fx:w*0.416]-%[fx:h*0.075] -crop 66.6x100%+0+0)],
    'pct:0,7.5,66.6,100' => [qw(-set page -%[fx:w*0]-%[fx:h*0.075] -crop 66.6x100%+0+0)],
    'pct:0,0,66.6,100' => [qw(-crop 66.6x100%+0+0)],

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
    is_deeply([IIIF::Magick::convert_args($req)], $args, "$req");
}

{
    local $^O = 'MSWin32';
    my $cmd = convert_command(IIIF::Request->new("pct:50"));
    like $cmd, qr{^(magick )?convert -resize "50%"$}, "Windows shell escape";
}

done_testing;
