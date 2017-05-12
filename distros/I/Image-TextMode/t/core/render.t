use Test::More tests => 11;

use strict;
use warnings;

use GD qw( :cmp );

use_ok( 'Image::TextMode::Format::ANSI' );
use_ok( 'Image::TextMode::Renderer::GD' );

my $image = Image::TextMode::Format::ANSI->new;
isa_ok( $image, 'Image::TextMode::Format::ANSI' );
$image->pixeldata(
    [   [   { char => 'T', attr => 8 },
            { char => 'E', attr => 207 },
            { char => 'S', attr => 68 },
            { char => 'T', attr => 35 },
        ]
    ],
);
$image->width( 4 );
$image->height( 1 );

my $renderer = Image::TextMode::Renderer::GD->new;
isa_ok( $renderer, 'Image::TextMode::Renderer::GD' );

# fullscale tests
my @tests = (
    [ {}, 'default' ],
    [ { blink_mode => 1 }, 'blink' ],
    [ { '9th_bit'  => 1 }, '9th_bit' ],
    [ { ced        => 1 }, 'ced' ],
);

_render( @$_ ) for @tests;

sub _render {
    my ( $options, $file ) = @_;

    my $generated
        = $renderer->fullscale( $image, { format => 'object', %$options } );
    my $expected = GD::Image->new( "t/core/render/$file.png" );

    ok( !( $expected->compare( $generated ) & GD_CMP_IMAGE ),
        "render() [$file]" );

}

# thumbnail test
my $generated = $renderer->thumbnail( $image, { format => 'object' } );
isa_ok( $generated, 'GD::Image' );
is( $generated->width,  4, 'thumbnail() - width' );
is( $generated->height, 2, 'thumbnail() - height' );
