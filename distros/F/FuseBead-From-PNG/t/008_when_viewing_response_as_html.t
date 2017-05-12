# -*- perl -*-

# t/008_when_viewing_response_as_html.t - Test module's HTML view option

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use FuseBead::From::PNG;

use FuseBead::From::PNG::Const qw(:all);

use Data::Debug;

# ----------------------------------------------------------------------

my $tests = 0;

should_return_properly_formatted_HTML();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_return_properly_formatted_HTML {
    my ($width, $height, $unit_size) = (16, 16, 16);

    # Pick a random bead color to test this part
    my $color = do {
        my @color_list = BEAD_COLORS;
        my $num_bead_colors = scalar( @color_list );
        $color_list[ int(rand() * $num_bead_colors) ];
    };
    my $color_rgb = do {
        my ($r, $g, $b) = ($color . '_RGB_COLOR_RED', $color . '_RGB_COLOR_GREEN', $color . '_RGB_COLOR_BLUE');
        [ FuseBead::From::PNG::Const->$r, FuseBead::From::PNG::Const->$g, FuseBead::From::PNG::Const->$b ];
    };

    my $id    = "${color}_1x1x1";
    my $class = lc($color);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my $color_info = $object->bead_colors->{ $color };

    my $plan_length = $width / $unit_size * FuseBead::From::PNG::Const->BEAD_DIAMETER;
    my $plan_height = $height / $unit_size * FuseBead::From::PNG::Const->BEAD_DIAMETER;
    my $plan_length_in = $plan_length * FuseBead::From::PNG::Const->MILLIMETER_TO_INCH;
    my $plan_height_in = $plan_height * FuseBead::From::PNG::Const->MILLIMETER_TO_INCH;

    my $bead_diameter = FuseBead::From::PNG::Bead->new({ color => $color })->diameter;
    my $border_width  = 1;
    my $pixel_length  = $bead_diameter * FuseBead::From::PNG::Const->MILLIMETER_TO_PIXEL - $border_width * 2;

my $expected = <<"HTML";
<style>
.picture { border-collapse: collapse; page-break-before: always; }
.picture td { height: ${pixel_length}px; width: ${pixel_length}px; border: solid black ${border_width}px; padding: 0; }
.bead_display { margin-top: 1em; }
.$class { background: #$color_info->{'hex_color'}; }
</style>

<section class="info">
<h2>Info</h2>
<table><tbody>
<tr><td>Length:</td><td>$plan_length mm</td></tr>
<tr><td>Height:</td><td>$plan_height mm</td></tr>
</tbody></table>
<table><tbody>
<tr><td>Length:</td><td>$plan_length_in in.</td></tr>
<tr><td>Height:</td><td>$plan_height_in in.</td></tr>
</tbody></table>
</section>

<section class="bead_list">
<h2>Bead List</h2>
<p>Total Beads - 1</p>
<table><thead><tr><th>Bead</th><th>Quantity</th></thead><tbody>
<tr><td>$color_info->{'name'}</td><td>1</td></tr>
</tbody></table>
</section>

<section class="bead_display">
<table class="picture"><tbody>
<tr><td title="$color_info->{'name'}" class="$class"></td></tr>
</tbody></table>
</section>
HTML

    my $result = $object->process(view => 'HTML');

    cmp_ok(ref($result) ? "it's a ref - " . ref($result) : "it's a scalar", 'eq', "it's a scalar", 'Result is a SCALAR and not a reference');

    is_deeply($result, $expected, "HTML generated correctly");

    $tests += 2;
}
