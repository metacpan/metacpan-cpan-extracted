use Test::More tests => 6;

use strict;
use warnings;

$ENV{ IMAGE_TEXTMODE_NOXS } = 1;

use_ok( 'Image::TextMode::Format::ANSI' );

my $ansi = Image::TextMode::Format::ANSI->new;
$ansi->read( "t/ansi/data/blink.ans" );

isa_ok( $ansi, 'Image::TextMode::Format::ANSI' );
is( $ansi->width,  4, "blink.ans width()" );
is( $ansi->height, 1, "blink.ans height()" );

is( $ansi->render_options->{ blink_mode }, 0, "iCEColor On" );

is_deeply(
    $ansi->pixeldata,
    [   [   { char => 'T', attr => 8 },
            { char => 'E', attr => 207 },
            { char => 'S', attr => 68 },
            { char => 'T', attr => 35 },
        ]
    ],
    "blink.ans pixeldata"
);
