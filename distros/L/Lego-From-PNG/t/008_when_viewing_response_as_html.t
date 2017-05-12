# -*- perl -*-

# t/008_when_viewing_response_as_html.t - Test module's HTML view option

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use Lego::From::PNG;

use Lego::From::PNG::Const qw(:all);

use Data::Debug;

# ----------------------------------------------------------------------

my $tests = 0;

should_return_properly_formatted_HTML();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_return_properly_formatted_HTML {
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

    my $id    = "${color}_1x1x1";
    my $class = lc($color);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my $color_info = $object->lego_colors->{ $color };

    my @length_classes;
    push @length_classes, ".length_$_ { width: ${_}em; }" for LEGO_BRICK_LENGTHS;
    my $length_classes = join("\n", @length_classes);

    my $plan_depth  = Lego::From::PNG::Const->LEGO_UNIT_DEPTH * Lego::From::PNG::Const->LEGO_UNIT;
    my $plan_length = $width / $unit_size * Lego::From::PNG::Const->LEGO_UNIT_LENGTH * Lego::From::PNG::Const->LEGO_UNIT;
    my $plan_height = ($height / $unit_size * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT * Lego::From::PNG::Const->LEGO_UNIT) + Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT;

my $expected = <<"HTML";
<style>
.picture td { height: 1em; }
$length_classes
.$class { background: #$color_info->{'hex_color'}; }
</style>

<section class="info">
<h2>Info</h2>
<table><tbody>
<tr><td>Depth:</td><td>$plan_depth mm</td></tr>
<tr><td>Length:</td><td>$plan_length mm</td></tr>
<tr><td>Height:</td><td>$plan_height mm</td></tr>
</tbody></table>
</section>

<section class="brick_list">
<h2>Brick List</h2>
<p>Total Bricks - 1</p>
<table><thead><tr><th>Brick</th><th>Quantity</th></thead><tbody>
<tr><td>$color_info->{'official_name'} 1x1x1</td><td>1</td></tr>
</tbody></table>
</section>

<section class="brick_display">
<h2>Picture</h2>
<table class="picture" border="1"><tbody>
<tr><td colspan="1" title="$color_info->{'official_name'} 1x1x1" class="$class length_1"></td></tr>
</tbody></table>
</section>
HTML

    my $result = $object->process(view => 'HTML');

    cmp_ok(ref($result) ? "it's a ref - " . ref($result) : "it's a scalar", 'eq', "it's a scalar", 'Result is a SCALAR and not a reference');

    is_deeply($result, $expected, "HTML generated correctly");

    $tests += 2;
}
