
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Calculator;

########################################################################
sub complement { # -- :start_values, @target_delta, +steps, +tilt, +skew, :space  --> @:values
    my ($start_color, $target_delta, $steps, $tilt, $skew, $color_space) = @_;
    return unless ref $color_space eq 'Graphics::Toolkit::Color::Space';
    return 'need a cylindrical color space from the HSL family as color space' unless $color_space->family eq 'HSL';
	my 	$axis_position = {
	             h => $color_space->pos_from_axis_role('hue'),
	             s => $color_space->pos_from_axis_role('saturation'),
	             l => $color_space->pos_from_axis_role('lightness'),
	};
	my $hue_half_max = $color_space->shape->axis_value_max( $axis_position->{'h'} ) / 2;

    my $start_tuple = $start_color->shaped( $color_space->name );
    $start_tuple = $color_space->rotate( $start_tuple );
    my $target_values = [@$start_tuple];       # target = THE complement + usr changes
    $target_values->[$axis_position->{'h'}] += $hue_half_max;
    $target_delta->[$_] //= 0 for 0 .. 2;
    $target_values->[$_] += $target_delta->[$_] for 0 .. 2;
    $target_values = $color_space->clamp( $target_values );

    $target_delta->[$axis_position->{'s'}] = $target_values->[$axis_position->{'s'}] - $start_tuple->[$axis_position->{'s'}];
    $target_delta->[$axis_position->{'l'}] = $target_values->[$axis_position->{'l'}] - $start_tuple->[$axis_position->{'l'}];

    my $result_count = int abs $steps;
    my $scaling_exponent = abs($tilt) + 1;
    my @hue_pos_normal = map {($_ * 2 / $result_count) ** $scaling_exponent} 1 .. ($result_count - 1) / 2;
    @hue_pos_normal = map {1 - $_} reverse @hue_pos_normal if $tilt > 0;            # reverse tilt effect if tilt negative

    my $hue_target_delta  = $hue_half_max + $target_delta->[$axis_position->{'h'}]; # real value size of half complement circle
    my @result = ();
    for my $hue_position (@hue_pos_normal){
		my $tuple = [];
		$tuple->[$axis_position->{'h'}] = $start_tuple->[$axis_position->{'h'}] + ($hue_target_delta                      * $hue_position);
		$tuple->[$axis_position->{'s'}] = $start_tuple->[$axis_position->{'s'}] + ($target_delta->[$axis_position->{'s'}] * $hue_position);
		$tuple->[$axis_position->{'l'}] = $start_tuple->[$axis_position->{'l'}] + ($target_delta->[$axis_position->{'l'}] * $hue_position);
		$tuple->[$axis_position->{'l'}] -= ($hue_position <= 0.5) ? ($skew * $hue_position * 2) : ($skew * (2 - ( $hue_position * 2)));
		push @result, Graphics::Toolkit::Color::Values->new_from_tuple( $tuple, $color_space->name );
	}
    push @result, Graphics::Toolkit::Color::Values->new_from_tuple( $target_values, $color_space->name)
        if $result_count == 1 or not $result_count % 2;
    $hue_target_delta = $hue_half_max - $target_delta->[$axis_position->{'h'}];
    @hue_pos_normal = map {1 - $_} reverse @hue_pos_normal;
    for my $hue_position (@hue_pos_normal){
		my $tuple = [];
		$tuple->[$axis_position->{'h'}] = $target_values->[$axis_position->{'h'}] + ($hue_target_delta                      * $hue_position);
		$tuple->[$axis_position->{'s'}] = $target_values->[$axis_position->{'s'}] - ($target_delta->[$axis_position->{'s'}] * $hue_position);
		$tuple->[$axis_position->{'l'}] = $target_values->[$axis_position->{'l'}] - ($target_delta->[$axis_position->{'l'}] * $hue_position);
		$tuple->[$axis_position->{'l'}] += ($hue_position <= 0.5) ? ($skew * $hue_position * 2) : ($skew * (2 - ( $hue_position * 2)));
		push @result, Graphics::Toolkit::Color::Values->new_from_tuple( $tuple, $color_space->name );
	}
    push @result, $start_color if $result_count > 1;
    return @result;
}

########################################################################
sub analogous { # :start_values, :next_values -- +steps, +tilt, :space --> @:values
    my ($start_color, $next_color, $steps, $tilt, $color_space) = @_;
    $steps = int $steps;
    return $start_color if $steps == 1;
    return $start_color, $next_color if $steps == 2;
    my @result = ($start_color, $next_color);
    my $start_tuple = $start_color->normalized( $color_space->name );
    my $next_tuple = $next_color->normalized( $color_space->name );
    my $delta_tuple = $color_space->delta( $start_tuple, $next_tuple );
    for my $color_nr (3 .. $steps){
		for my $axis_nr ($color_space->basis->axis_iterator){
			$delta_tuple->[$axis_nr] *= 1 + $tilt;
			$next_tuple->[$axis_nr] += $delta_tuple->[$axis_nr];
		}
        my $next_color = $start_color->new_from_tuple( $next_tuple, $color_space->name, 'normal', 'raw' );
		last unless $next_color->is_in_gamut( $color_space->name );
		push @result, $next_color;
	}
    return @result;
}

########################################################################
sub gradient { # @:color_values -- +steps, +tilt, :space --> @:values
    my ($colors, $steps, $tilt, $color_space) = @_;
    my $scaling_exponent = abs($tilt) + 1; # tilt = exponential scaling
    my $segment_count = @$colors - 1;
    my @percent_in_gradient = map {(($_-1) / ($steps-1)) ** $scaling_exponent} 2 .. $steps - 1;
    @percent_in_gradient = map {1 - $_} reverse @percent_in_gradient if $tilt < 0;
    my @result = ($colors->[0]);
    for my $step_nr (2 .. $steps - 1){
        my $percent_in_gradient = $percent_in_gradient[$step_nr-2];
        my $current_segment_nr = int ($percent_in_gradient * $segment_count);
        my $percent_in_segment = $segment_count * ($percent_in_gradient - ($current_segment_nr / $segment_count));
        push @result, Graphics::Toolkit::Color::Calculator::mix(
                          $colors->[$current_segment_nr], [ $colors->[$current_segment_nr+1] ], $percent_in_segment, $color_space );
    }
    push @result, pop @$colors if $steps > 1;
    return @result;
}

########################################################################
my $adj_len_at_45_deg = sqrt(2) / 2;

sub cluster { # :center_values, @+|+radius +min_distance -- :space --> @:values
    my ($center_color, $cluster_radius, $color_distance, $color_space) = @_;
    my $center_tuple = $center_color->shaped( $color_space->name );
    my $center_x = $center_tuple->[0];
    my $center_y = $center_tuple->[1];
    my $center_z = $center_tuple->[2];
    my @result_values;
    if (ref $cluster_radius) { # cuboid shaped cluster
        my $colors_in_direction = int $cluster_radius->[0] / $color_distance;
        my $corner_value = $center_tuple->[0] - ($colors_in_direction * $color_distance);
        @result_values = map {[$corner_value + ($_ * $color_distance)]} 0 .. 2 * $colors_in_direction;
        for my $axis_index (1 .. $color_space->axis_count - 1){
            my $colors_in_direction = int $cluster_radius->[$axis_index] / $color_distance;
            my $corner_value = $center_tuple->[$axis_index] - ($colors_in_direction * $color_distance);
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
    return map { Graphics::Toolkit::Color::Values->new_from_tuple( $_, $color_space->name )}
           grep { $color_space->is_in_linear_bounds($_) } @result_values;
}

1;
