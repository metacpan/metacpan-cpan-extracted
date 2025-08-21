
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;

my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $half_hue_max = $HSL->shape->axis_value_max(0) / 2;
########################################################################
sub complement { # :base_color +steps +tilt %target_delta --> @:values
    my ($start_color, $steps, $tilt, $target_delta) = @_;
    my $start_values = $start_color->shaped( $HSL->name );
    my $target_values = [@$start_values];
    $target_values->[0] += $half_hue_max;
    for my $axis_index (0 .. 2) {
        $target_delta->[$axis_index] = 0 unless defined $target_delta->[$axis_index];
        $target_values->[$axis_index] += $target_delta->[$axis_index];
    }
    $target_values = $HSL->clamp( $target_values );  # bring back out of bound linear axis values
    $target_delta->[1] = $target_values->[1] - $start_values->[1];
    $target_delta->[2] = $target_values->[2] - $start_values->[2];
    my $result_count = int abs $steps;
    my $scaling_exponent = abs($tilt) + 1;
    my @hue_percent = map {($_ * 2 / $result_count) ** $scaling_exponent} 1 .. ($result_count - 1) / 2;
    @hue_percent = map {1 - $_} reverse @hue_percent if $tilt > 0;
    my $hue_delta = $half_hue_max + $target_delta->[0]; # real value size of half complement circle
    my @result = ();
    push( @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                    [$start_values->[0] + ($hue_delta         * $_),
                     $start_values->[1] + ($target_delta->[1] * $_),
                     $start_values->[2] + ($target_delta->[2] * $_)], $HSL->name)) for @hue_percent;
    push @result, Graphics::Toolkit::Color::Values->new_from_tuple( $target_values, $HSL->name)
        if $result_count == 1 or not $result_count % 2;
    $hue_delta = $half_hue_max - $target_delta->[0];
    @hue_percent = map {1 - $_} reverse @hue_percent;
    push( @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                    [$target_values->[0] + ($hue_delta         * $_),
                     $target_values->[1] - ($target_delta->[1] * $_),
                     $target_values->[2] - ($target_delta->[2] * $_)], $HSL->name)) for @hue_percent;
    push @result, $start_color if $result_count > 1;
    return @result;
}

########################################################################
sub gradient { # @:colors, +steps, +tilt, :space --> @:values
    my ($colors, $steps, $tilt, $color_space) = @_;
    my $scaling_exponent = abs($tilt) + 1; # tilt = exponential scaling
    my $segment_count = @$colors - 1;
    my @percent_in_gradient = map {(($_-1) / ($steps-1)) ** $scaling_exponent} 2 .. $steps - 1;
    @percent_in_gradient = map {1 - $_} reverse @percent_in_gradient if $tilt < 0;
    my @result = ($colors->[0]);
    for my $step_nr (2 .. $steps - 1){
        my $percent_in_gradient = $percent_in_gradient[$step_nr-2];
        my $current_segment_nr = int ($percent_in_gradient * $segment_count);
        my $percent_in_segment = 100 * $segment_count * ($percent_in_gradient - ($current_segment_nr / $segment_count));
        push @result, $colors->[$current_segment_nr]->mix (
                          [{color => $colors->[$current_segment_nr+1], percent => $percent_in_segment}], $color_space );
    }
    push @result, pop @$colors if $steps > 1;
    return @result;
}

########################################################################
my $adj_len_at_45_deg = sqrt(2) / 2;

sub cluster { # :values, +radius @+|+distance, :space --> @:values
    my ($center_color, $cluster_radius, $color_distance, $color_space) = @_;
    my $color_space_name = $color_space->name;
    my $center_values = $center_color->shaped( $color_space_name );
    my $center_x = $center_values->[0];
    my $center_y = $center_values->[1];
    my $center_z = $center_values->[2];
    my @result_values;
    if (ref $cluster_radius) { # cuboid shaped cluster
        my $colors_in_direction = int $cluster_radius->[0] / $color_distance;
        my $corner_value = $center_values->[0] - ($colors_in_direction * $color_distance);
        @result_values = map {[$corner_value + ($_ * $color_distance)]} 0 .. 2 * $colors_in_direction;
        for my $axis_index (1 .. $color_space->axis_count - 1){
            my $colors_in_direction = int $cluster_radius->[$axis_index] / $color_distance;
            my $corner_value = $center_values->[$axis_index] - ($colors_in_direction * $color_distance);
            @result_values = map {
                my @good_values = @$_[0 .. $axis_index-1];
                map {[@good_values, ($corner_value + ($_ * $color_distance))]} 0 .. 2 * $colors_in_direction;
            } @result_values;
        }
    } else {                    # ball shaped cluster (FCC)
        my $layer_distance = sqrt( 2 * $color_distance * $color_distance ) / 2;
        for my $layer_nr (0 .. $cluster_radius / $layer_distance){
            my $layer_height = $layer_nr * $layer_distance;
            my $layer_z_up   = $center_z + $layer_height;
            my $layer_z_dn   = $center_z - $layer_height;
            my $layer_radius = sqrt( ($cluster_radius**2) - ($layer_height**2) );
            my $radius_in_colors = $layer_radius / $color_distance;
            if ($layer_nr % 2){ # odd layer of cuboctahedral packing
                my $contour_cursor = int ($radius_in_colors - 0.5);
                my $grid_row_count = ($radius_in_colors * $adj_len_at_45_deg) - .5;
                next if $grid_row_count < 0;
                my @grid = ();
                for my $x_index (0 .. $grid_row_count){
                    $contour_cursor-- if sqrt( (($contour_cursor+.5)**2) + (($x_index+.5)**2) ) > $radius_in_colors;
                    $grid[$x_index] = $contour_cursor;
                    $grid[$contour_cursor] = $x_index;
                }
                for my $x_index (0 .. $#grid){
                    my $delta_x = (0.5 + $x_index) * $color_distance;
                    my ($x1, $x2) = ($center_x + $delta_x, $center_x - $delta_x);
                    for my $y_index (0 .. $grid[$x_index]){
                        my $delta_y = (0.5 + $y_index) * $color_distance;
                        my ($y1, $y2) = ($center_y + $delta_y, $center_y - $delta_y);
                        push @result_values,
                            [$x1, $y1, $layer_z_up], [$x2, $y1, $layer_z_up],
                            [$x1, $y2, $layer_z_up], [$x2, $y2, $layer_z_up],
                            [$x1, $y1, $layer_z_dn], [$x2, $y1, $layer_z_dn],
                            [$x1, $y2, $layer_z_dn], [$x2, $y2, $layer_z_dn];
                    }
                }
            } else {            # even layer of cuboctahedral packing
                my $grid_row_count = int $radius_in_colors;
                my @grid = ($grid_row_count);
                $grid[$grid_row_count] = 0;
                my $contour_cursor = $grid_row_count;
                for my $x_index (1 .. $layer_radius * $adj_len_at_45_deg / $color_distance){
                    $contour_cursor-- if sqrt(($contour_cursor**2) + ($x_index**2)) > $radius_in_colors;
                    $grid[$x_index] = $contour_cursor;
                    $grid[$contour_cursor] = $x_index;
                }
                my @layer_values = map {[$center_x + ($_ * $color_distance), $center_y, $layer_z_up]}
                        -$grid_row_count .. $grid_row_count;
                for my $y_index (1 .. $grid_row_count){
                    my $delta_y = $y_index * $color_distance;
                    my ($y1, $y2) = ($center_y + $delta_y, $center_y - $delta_y);
                    for my $x_index (-$grid[$y_index] .. $grid[$y_index]){
                        my $x = $center_x + ($x_index * $color_distance);
                        push @layer_values, [$x, $y1, $layer_z_up], [$x, $y2, $layer_z_up];
                    }
                }
                if ($layer_nr > 0){
                    push @result_values, [$_->[0], $_->[1], $layer_z_dn] for @layer_values;
                }
                push @result_values, @layer_values;
            }
        }
    }
    # check for linear space borders and constraints
    return map { Graphics::Toolkit::Color::Values->new_from_tuple( $_, $color_space_name )}
           grep { $color_space->is_in_linear_bounds($_) } @result_values;
}

1;
