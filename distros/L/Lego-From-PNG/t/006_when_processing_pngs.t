# -*- perl -*-

# t/006_when_processing_pngs.t - Test aspects of module's process method

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

should_return_empty_list_with_no_params();

should_return_the_right_count_of_blocks_of_colors();

should_return_lego_colors_approximated_from_a_list_containing_blocks_of_colors();

should_return_a_list_of_lego_bricks_per_row_of_png();

should_only_return_bricks_in_the_list_that_are_whitelisted_by_color();

should_only_return_bricks_in_the_list_that_are_whitelisted_by_brick_dimension();

should_only_return_bricks_in_the_list_that_are_whitelisted_by_color_and_brick_dimension();

should_return_information_about_the_generated_plan();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_return_empty_list_with_no_params {
    my $object = Lego::From::PNG->new();

    my $result = $object->process();

    is_deeply($result, { bricks => {}, plan => [] }, "Empty list returned");

    $tests++;
}

sub should_return_the_right_count_of_blocks_of_colors {
    my ($width, $height, $unit_size) = (1024, 768, 16);
    my $num_blocks = ($width / $unit_size) * ($height / $unit_size);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my @result = $object->_png_blocks_of_color();

    cmp_ok(scalar(@result), '==', $num_blocks, 'block count should be correct');

    $tests++;
}

sub should_return_lego_colors_approximated_from_a_list_containing_blocks_of_colors {
    my ($width, $height, $unit_size) = (32, 32, 16);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

    my @blocks = $object->_png_blocks_of_color();

    my @result = $object->_approximate_lego_colors(blocks => \@blocks);

    cmp_ok(scalar(@result), '==', scalar(@blocks), 'approximate color count and block count are the same');

    $tests++;

    # Generate each lego color as a test block and it should approximate back to that same color
    # Note: Dark red and green are so close that they can be either...
    my @test_blocks = map {
        +{
            r   => $_->{ 'rgb_color' }[0],
            g   => $_->{ 'rgb_color' }[1],
            b   => $_->{ 'rgb_color' }[2],
            cid => $_->{ 'cid' } =~ m/^ ( DARK_GREEN | DARK_RED ) $/x ? 'DARK_GREEN_OR_DARK_RED' : $_->{ 'cid' },
        }
    } values %{ $object->lego_colors };

    @result = $object->_approximate_lego_colors(blocks => \@test_blocks);

    @result = map { $_ =~ m/^ ( DARK_GREEN | DARK_RED ) $/x ? 'DARK_GREEN_OR_DARK_RED' : $_ } @result;

    for(my $i = 0; $i < scalar( @test_blocks ); $i++) {
        my $cid = $test_blocks[$i]{'cid'};
        cmp_ok($result[$i], 'eq', $cid, "$cid approximated correctly");
        $tests++;
    }
}

sub should_return_a_list_of_lego_bricks_per_row_of_png {
    my $unit_size = 16;

    for my $brick_length ( LEGO_BRICK_LENGTHS ) {
        my ($width, $height) = ($brick_length * $unit_size, $unit_size);

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

        my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

        my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

        my @blocks = $object->_png_blocks_of_color();

        my $num_block_colors = do {
            my %colors;
            $colors{ join('_', $_->{'r'}, $_->{'g'}, $_->{'b'}) } = 1 for @blocks;
            scalar(keys %colors);
        };

        cmp_ok($num_block_colors, '==', 1, "Only one color was used to generate blocks of length $brick_length");
        $tests++;

        is_deeply($blocks[0], {
            r => $object->lego_colors->{ $color }->{'rgb_color'}->[0],
            g => $object->lego_colors->{ $color }->{'rgb_color'}->[1],
            b => $object->lego_colors->{ $color }->{'rgb_color'}->[2],
        }, "The color we randomly chose is being used for brick of length $brick_length");
        $tests++;

        my @units = $object->_approximate_lego_colors(blocks => \@blocks);

        my @bricks = $object->_generate_brick_list(units => \@units);

        my $id = $color.'_1x'.$brick_length.'x1';

        is_deeply($bricks[0]->flatten, {
            length => $brick_length,
            height => 1,
            depth  => 1,
            color  => $color,
            id     => $id,
            meta   => {
                y => 0,
            },
        }, "Brick returned is the correct dimensions and color for brick of length $brick_length");
        $tests++;
    }
}


sub should_only_return_bricks_in_the_list_that_are_whitelisted_by_color {
    my $unit_size = 16;

    my $brick_length = 4;

    my ($width, $height) = ($brick_length * $unit_size, $unit_size);

    # Pick a random lego color to test this part
    my $starting_color    = 'WHITE';
    my $whitelisted_color = 'BLACK';
    my $color_rgb = do {
        my ($r, $g, $b) = ($starting_color . '_RGB_COLOR_RED', $starting_color . '_RGB_COLOR_GREEN', $starting_color . '_RGB_COLOR_BLUE');
        [ Lego::From::PNG::Const->$r, Lego::From::PNG::Const->$g, Lego::From::PNG::Const->$b ];
    };

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, whitelist => [ $whitelisted_color ] });

    my $result = $object->process();

    my $expected = {
        color => $whitelisted_color,
        depth => 1,
        height => 1,
        id => "${whitelisted_color}_1x${brick_length}x1",
        length => $brick_length,
        meta => {
            y => 0
        },
    };

    is_deeply($result->{'plan'}[0], $expected, "Brick generated is of the whitelisted color we chose");

    $tests++;
}

sub should_only_return_bricks_in_the_list_that_are_whitelisted_by_brick_dimension {
    my $unit_size = 16;

    my $brick_length = 4;

    my ($width, $height) = ($brick_length * $unit_size, $unit_size);

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

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, whitelist => [ '1x3x1', '1x2x1', '1x1x1' ] });

    my $result = $object->process();

    my $expected = [
        {
            color => $color,
            depth => 1,
            height => 1,
            id => "${color}_1x3x1",
            length => 3,
            meta => {
                y => 0
            },
        },
        {
            color => $color,
            depth => 1,
            height => 1,
            id => "${color}_1x1x1",
            length => 1,
            meta => {
                y => 0
            },
        },
    ];

    is_deeply($result->{'plan'}, $expected, "Bricks generated are of the whitelisted dimensions we chose");

    $tests++;
}

sub should_only_return_bricks_in_the_list_that_are_whitelisted_by_color_and_brick_dimension {
    my $unit_size = 16;

    my $brick_length = 4;

    my ($width, $height) = ($brick_length * $unit_size, $unit_size);

    # Pick a random lego color to test this part
    my $starting_color    = 'WHITE';
    my $whitelisted_color = 'BLACK';
    my $color_rgb = do {
        my ($r, $g, $b) = ($starting_color . '_RGB_COLOR_RED', $starting_color . '_RGB_COLOR_GREEN', $starting_color . '_RGB_COLOR_BLUE');
        [ Lego::From::PNG::Const->$r, Lego::From::PNG::Const->$g, Lego::From::PNG::Const->$b ];
    };

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size, color => $color_rgb });

    my @whitelisted_bricks;
    for('1x3x1','1x2x1','1x1x1') {
        push @whitelisted_bricks, join('_', $whitelisted_color, $_);
    }

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, whitelist => \@whitelisted_bricks });

    my $result = $object->process();

    my $expected = [
        {
            color => $whitelisted_color,
            depth => 1,
            height => 1,
            id => "${whitelisted_color}_1x3x1",
            length => 3,
            meta => {
                y => 0
            },
        },
        {
            color => $whitelisted_color,
            depth => 1,
            height => 1,
            id => "${whitelisted_color}_1x1x1",
            length => 1,
            meta => {
                y => 0
            },
        },
    ];

    is_deeply($result->{'plan'}, $expected, "Bricks generated are of the whitelisted color and dimenstions we chose");

    $tests++;
}

sub should_return_information_about_the_generated_plan {
    my ($width, $height, $unit_size) = (256, 256, 16);

    my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

    my $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, metric => 1 });

    my $result = $object->process();

    my $plan_depth = Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_DEPTH;

    my $plan_length = ($width / $unit_size)
                * (Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_LENGTH);

    my $plan_height = (($height / $unit_size)
                * (Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT)) + Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT;

    my $expected_in_millimeters = {
        metric => {
            depth   => $plan_depth,
            length  => $plan_length,
            height  => $plan_height,
        },
    };

    is_deeply($result->{'info'}, $expected_in_millimeters, "Information about plan (in millimeters) correct");

    $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, imperial => 1 });

    $result = $object->process();

    $plan_depth = Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_DEPTH * Lego::From::PNG::Const->MILLIMETER_TO_INCH;

    $plan_length = ($width / $unit_size)
                * (Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_LENGTH * Lego::From::PNG::Const->MILLIMETER_TO_INCH);

    $plan_height = ((($height / $unit_size)
                * (Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT)) + Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT) * Lego::From::PNG::Const->MILLIMETER_TO_INCH;

    my $expected_in_inches = {
        imperial => {
            depth   => $plan_depth,
            length  => $plan_length,
            height  => $plan_height,
        }
    };

    is_deeply($result->{'info'}, $expected_in_inches, "Information about plan (in inches) is correct");

    $object = Lego::From::PNG->new({ filename => $png->filename, unit_size => $unit_size, metric => 1, imperial => 1 });

    $result = $object->process();

    my $expected_in_both = { %$expected_in_millimeters, %$expected_in_inches };

    is_deeply($result->{'info'}, $expected_in_both, "Information about plan, in both imperial and metric, is correct");

    $tests += 3;
}
