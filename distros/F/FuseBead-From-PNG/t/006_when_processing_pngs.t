# -*- perl -*-

# t/006_when_processing_pngs.t - Test aspects of module's process method

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

should_return_empty_list_with_no_params();

should_mirror_image_by_default();

should_return_the_right_count_of_beads_of_colors();

should_return_bead_colors_approximated_from_a_list_containing_beads_of_colors();

should_return_a_correct_list_of_beads();

should_only_return_beads_in_the_list_that_are_whitelisted_by_color();

should_return_a_list_of_bead_beads_with_sequentual_meta_refs();

should_return_information_about_the_generated_plan();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_return_empty_list_with_no_params {
    note("---- ". current_sub(). " ----\n");

    my $object = FuseBead::From::PNG->new({});

    my $result = $object->process();

    is_deeply($result, { beads => {}, plan => [] }, "Empty list returned");

    $tests++;
}

sub should_mirror_image_by_default {
    note("---- ". current_sub(). " ----\n");

    my $object = FuseBead::From::PNG->new({});

    my $result = $object->mirror();

    cmp_ok($result, '==', 1, "Image will be mirrored when generated as plans by default");

    $tests++;
}

sub should_return_the_right_count_of_beads_of_colors {
    note("---- ". current_sub(). " ----\n");

    my ($width, $height, $unit_size) = (1024, 768, 16);
    my $num_beads = ($width / $unit_size) * ($height / $unit_size);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

    my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my @result = $object->_png_blocks_of_color();

    cmp_ok(scalar(@result), '==', $num_beads, 'bead count should be correct');

    $tests++;
}

sub should_return_bead_colors_approximated_from_a_list_containing_beads_of_colors {
    note("---- ". current_sub(). " ----\n");

    my ($width, $height, $unit_size) = (32, 32, 16);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

    my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my @beads = $object->_png_blocks_of_color();

    my @result = $object->_approximate_bead_colors(blocks => \@beads);

    cmp_ok(scalar(@result), '==', scalar(@beads), 'approximate color count and bead count are the same');

    $tests++;

    # Generate each bead color as a test bead and it should approximate back to that same color
    # Note: Dark red and green are so close that they can be either...
    my @test_beads = map {
        +{
            r   => $_->{ 'rgb_color' }[0],
            g   => $_->{ 'rgb_color' }[1],
            b   => $_->{ 'rgb_color' }[2],
            cid => $_->{ 'cid' } =~ m/^ ( DARK_GREEN | DARK_RED ) $/x ? 'DARK_GREEN_OR_DARK_RED' : $_->{ 'cid' },
        }
    } values %{ $object->bead_colors };

    @result = $object->_approximate_bead_colors(blocks => \@test_beads);

    @result = map { $_ =~ m/^ ( DARK_GREEN | DARK_RED ) $/x ? 'DARK_GREEN_OR_DARK_RED' : $_ } @result;

    for(my $i = 0; $i < scalar( @test_beads ); $i++) {
        my $cid = $test_beads[$i]{'cid'};
        cmp_ok($result[$i], 'eq', $cid, "$cid approximated correctly");
        $tests++;
    }
}

sub should_return_a_correct_list_of_beads {
    note("---- ". current_sub(). " ----\n");

    my $unit_size = 16;

        my ($width, $height) = ($unit_size, $unit_size);

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

        my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

        my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

        my @blocks = $object->_png_blocks_of_color();

        my $num_bead_colors = do {
            my %colors;
            $colors{ join('_', $_->{'r'}, $_->{'g'}, $_->{'b'}) } = 1 for @blocks;
            scalar(keys %colors);
        };

        cmp_ok($num_bead_colors, '==', 1, "Only one color was used to generate beads");
        $tests++;

        is_deeply($blocks[0], {
            r => $object->bead_colors->{ $color }->{'rgb_color'}->[0],
            g => $object->bead_colors->{ $color }->{'rgb_color'}->[1],
            b => $object->bead_colors->{ $color }->{'rgb_color'}->[2],
        }, "The color we randomly chose is being used for bead");
        $tests++;

        my @units = $object->_approximate_bead_colors(blocks => \@blocks);

        my @beads = $object->_generate_bead_list(units => \@units);

        my $id = $color;

        is_deeply($beads[0]->flatten, {
            diameter => FuseBead::From::PNG::Const::BEAD_DIAMETER,
            color    => $color,
            id       => $id,
            meta     => {
                x   => 0,
                y   => 0,
                ref => 0,
            },
        }, "bead returned is the correct dimensions and color for bead");
        $tests++;
}


sub should_only_return_beads_in_the_list_that_are_whitelisted_by_color {
    note("---- ". current_sub(). " ----\n");

    my $unit_size = 16;

    my $bead_length = 4;

    my ($width, $height) = ($bead_length * $unit_size, $unit_size);

    # Pick a random bead color to test this part
    my $starting_color    = 'WHITE';
    my $whitelisted_color = 'BLACK';
    my $color_rgb = do {
        my ($r, $g, $b) = ($starting_color . '_RGB_COLOR_RED', $starting_color . '_RGB_COLOR_GREEN', $starting_color . '_RGB_COLOR_BLUE');
        [ FuseBead::From::PNG::Const->$r, FuseBead::From::PNG::Const->$g, FuseBead::From::PNG::Const->$b ];
    };

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, whitelist => [ $whitelisted_color ] });

    my $result = $object->process();

    my $expected = {
        color    => $whitelisted_color,
        diameter => FuseBead::From::PNG::Const::BEAD_DIAMETER,
        id       => "${whitelisted_color}",
        meta     => {
            x   => 0,
            y   => 0,
            ref => 0,
        },
    };

    is_deeply($result->{'plan'}[0], $expected, "bead generated is of the whitelisted color we chose");

    $tests++;
}

sub should_return_a_list_of_bead_beads_with_sequentual_meta_refs {
    note("---- ". current_sub(). " ----\n");

    my $unit_size    = 16;
    my $bead_length = 2;
    my $bead_height = 1;

    my ($width, $height) = ($bead_length * $unit_size, $bead_height * $unit_size);

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

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my @blocks = $object->_png_blocks_of_color();

    my $num_bead_colors = do {
        my %colors;
        $colors{ join('_', $_->{'r'}, $_->{'g'}, $_->{'b'}) } = 1 for @blocks;
        scalar(keys %colors);
    };

    my @units = $object->_approximate_bead_colors(blocks => \@blocks);

    my @beads = $object->_generate_bead_list(units => \@units);

    my $id = $color;

    for(my $i = 0; $i < @beads; $i++) {
        is_deeply($beads[$i]->flatten, {
            diameter => FuseBead::From::PNG::Const::BEAD_DIAMETER,
            color    => $color,
            id       => $id,
            meta     => {
                x   => $i,
                y   => 0,
                ref => $i,
            },
        }, "bead $i returned has the correct meta ref");
        $tests++;
    }
}

sub should_return_information_about_the_generated_plan {
    note("---- ". current_sub(). " ----\n");

    my ($width, $height, $unit_size) = (256, 256, 16);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

    my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my $result = $object->process();

    my $plan_length = FuseBead::From::PNG::Const->BEAD_DIAMETER * ($width / $unit_size);

    my $plan_height = FuseBead::From::PNG::Const->BEAD_DIAMETER * ($height / $unit_size);

    my $expected_in_millimeters = {
        metric => {
            length => $plan_length,
            height => $plan_height,
        },
    };

    $plan_length = FuseBead::From::PNG::Const->BEAD_DIAMETER * ($width / $unit_size) * FuseBead::From::PNG::Const->MILLIMETER_TO_INCH;

    $plan_height = FuseBead::From::PNG::Const->BEAD_DIAMETER * ($height / $unit_size) * FuseBead::From::PNG::Const->MILLIMETER_TO_INCH;

    my $expected_in_inches = {
        imperial => {
            length => $plan_length,
            height => $plan_height,
        }
    };

    my $expected_in_both = { rows => $width / $unit_size, cols => $height / $unit_size, %$expected_in_millimeters, %$expected_in_inches };

    is_deeply($result->{'info'}, $expected_in_both, "Information about plan, in both imperial and metric, is correct");

    $tests += 1;
}

# --- Utility subs ---

# Return description based on current subroutine
sub current_sub {
    my $sub = ((caller(1))[3]);

    $sub =~ s/^.*::([^:]+)$/$1/;
    $sub =~ s/_/ /g;

    return $sub;
}
