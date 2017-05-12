# -*- perl -*-

# t/007_when_viewing_response_as_json.t - Test module's JSON view option

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use Lego::From::PNG;

use Lego::From::PNG::Const qw(:all);

use JSON;

use Data::Debug;

# ----------------------------------------------------------------------

my $tests = 0;

should_return_properly_formatted_JSON();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_return_properly_formatted_JSON {
    my ($width, $height, $unit_size) = (16, 16, 16);

    # Pick a random lego color to test this part
    my $color = do {
        my @color_list = LEGO_COLORS;
        my $num_lego_colors = scalar( @color_list );
        $color_list[ int(rand() * $num_lego_colors) ];
    };
    my $color_rgb = do {
        my ($r, $g, $b) = ($color . '_RGB_COLOR_RED', $color . '_RGB_COLOR_GREEN', $color . '_RGB_COLOR_BLUE');
        [ Lego::From::PNG::Const->$r, Lego::From::PNG::Const->$g, Lego::From::PNG::Const->$b ];
    };

    my $id = "${color}_1x1x1";

    my $expected = {
        bricks => {
            $id   => {
            color    => $color,
            height   => 1,
            depth    => 1,
            id       => $id,
            quantity => 1,
            length   => 1,
            }
        },
        plan => [
            {
                color  => $color,
                height => 1,
                depth  => 1,
                id     => $id,
                length => 1,
                meta   => {
                    y => 0,
                },
            }
        ],
        info => {
            metric => {
                depth  => Lego::From::PNG::Const->LEGO_UNIT_DEPTH * Lego::From::PNG::Const->LEGO_UNIT,
                length => $width / $unit_size * Lego::From::PNG::Const->LEGO_UNIT_LENGTH * Lego::From::PNG::Const->LEGO_UNIT,
                height => ($height / $unit_size * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT * Lego::From::PNG::Const->LEGO_UNIT) + Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT,
            }
        }
    };

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my $result = $object->process(view => 'JSON');

    cmp_ok(ref($result) ? "it's a ref - " . ref($result) : "it's a scalar", 'eq', "it's a scalar", 'Result is a SCALAR and not a reference');

    my $hash = eval { JSON->new->decode( $result ) } || {};

    is_deeply($hash, $expected, "JSON decoded back to hash correctly");

    $tests += 2;
}
