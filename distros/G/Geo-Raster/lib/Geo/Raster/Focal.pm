## @class Geo::Raster::Focal
# @brief Adds focal operations into Geo::Raster
# @note Although the methods have the prefix Geo::Raster::Focal these
# are really Geo::Raster methods.
package Geo::Raster;

use strict;

## @method void set(@cell, $value)
#
# @brief A focal set.
#
# @param[in] cell The center cell of the focal area.
# @param[in] value A reference to a focal array of values.

## @method @get(@cell, $distance)
# 
# @brief A focal get.
#
# If the cell has a nodata or it is out-of-world value undef is returned.
# @param[in] cell The center cell of the focal area.
# @param[in] distance Integer value that specifies the focal area. The
# focal area is a rectangle, whose side is 2*distance+1 wide.
# @return Values of the cell or its neighborhood cells.

## @method Geo::Raster focal_sum(listref mask, @cell)
#
# @brief A focal sum.
#
# @param[in] mask The focal area defined as a 2D anonymous integer
# array. The width and height of the array must be 2d+1, where d is
# the max horizontal and vertical distance from the central cell.
# @param[in] cell (optional) The cell for which the focal sum is
# computed. If not given, the focal sum is computed for the whole
# raster.
# @return the focal sum, either as a single number or as a new
# raster. If no cell is given and executed in void context, changes
# this raster.
sub focal_sum {
    my $self = shift;
    my $mask = shift;
    if (@_) {
	my($i, $j) = @_;
	my $x = ral_grid_focal_sum($self->{GRID}, $i, $j, $mask);
	return $x;
    } else {
	my $grid = ral_grid_focal_sum_grid($self->{GRID}, $mask);
	if (defined wantarray) {
	    $grid = new Geo::Raster($grid);
	    return $grid;
	} else {
	    ral_grid_destroy($self->{GRID});
	    $self->{GRID} = $grid;
	}
    }
}

## @method Geo::Raster focal_mean(listref mask, @cell)
#
# @brief A focal mean.
#
# @param[in] mask The focal area defined as a 2D anonymous integer
# array. The width and height of the array must be 2d+1, where d is
# the max horizontal and vertical distance from the central cell.
# @param[in] cell (optional) The cell for which the focal mean is
# computed. If not given, the focal mean is computed for the whole
# raster.
# @return the focal mean, either as a single number or as a new
# raster. If no cell is given and executed in void context, changes
# this raster.
sub focal_mean {
    my $self = shift;
    my $mask = shift;
    if (@_) {
	my($i, $j) = @_;
	my $x = ral_grid_focal_mean($self->{GRID}, $i, $j, $mask);
	return $x;
    } else {
	my $grid = ral_grid_focal_mean_grid($self->{GRID}, $mask);
	if (defined wantarray) {
	    $grid = new Geo::Raster($grid);
	    return $grid;
	} else {
	    ral_grid_destroy($self->{GRID});
	    $self->{GRID} = $grid;
	}
    }
}

## @method Geo::Raster focal_variance(listref mask, @cell)
#
# @brief A focal variance.
#
# @param[in] mask The focal area defined as a 2D anonymous integer
# array. The width and height of the array must be 2d+1, where d is
# the max horizontal and vertical distance from the central cell.
# @param[in] cell (optional) The cell for which the focal variance is
# computed. If not given, the focal variance is computed for the whole
# raster.
# @return the focal variance, either as a single number or as a new
# raster. If no cell is given and executed in void context, changes
# this raster.
sub focal_variance {
    my $self = shift;
    my $mask = shift;
    if (@_) {
	my($i, $j) = @_;
	my $x = ral_grid_focal_variance($self->{GRID}, $i, $j, $mask);
	return $x;
    } else {
	my $grid = ral_grid_focal_variance_grid($self->{GRID}, $mask);
	if (defined wantarray) {
	    $grid = new Geo::Raster($grid);
	    return $grid;
	} else {
	    ral_grid_destroy($self->{GRID});
	    $self->{GRID} = $grid;
	}
    }
}

## @method Geo::Raster focal_count(listref mask, @cell)
#
# @brief A focal count of data cells.
#
# @param[in] mask The focal area defined as a 2D anonymous integer
# array. The width and height of the array must be 2d+1, where d is
# the max horizontal and vertical distance from the central cell.
# @param[in] cell (optional) The cell for which the focal count is
# computed. If not given, the focal count is computed for the whole
# raster.
# @return the focal count, either as a single number or as a new
# raster. If no cell is given and executed in void context, changes
# this raster.
sub focal_count {
    my $self = shift;
    my $mask = shift;
    if (@_) {
	my($i, $j) = @_;
	my $x = ral_grid_focal_count($self->{GRID}, $i, $j, $mask);
	return $x;
    } else {
	my $grid = ral_grid_focal_count_grid($self->{GRID}, $mask);
	if (defined wantarray) {
	    $grid = new Geo::Raster($grid);
	    return $grid;
	} else {
	    ral_grid_destroy($self->{GRID});
	    $self->{GRID} = $grid;
	}
    }
}

## @method Geo::Raster focal_count_of(listref mask, $value, @cell)
#
# @brief A focal count of values.
#
# @param[in] mask The focal area defined as a 2D anonymous integer
# array. The width and height of the array must be 2d+1, where d is
# the max horizontal and vertical distance from the central cell.
# @param[in] value The value whose count in the focal area is to be
# computed.
# @param[in] cell (optional) The cell for which the focal count of
# values is computed. If not given, the focal count_of is computed for
# the whole raster.
# @return the focal count of values, either as a single number or as a
# new raster. If no cell is given and executed in void context,
# changes this raster.
sub focal_count_of {
    my $self = shift;
    my $mask = shift;
    my $value = shift;
    if (@_) {
	my($i, $j) = @_;
	my $x = ral_grid_focal_count_of($self->{GRID}, $i, $j, $mask, $value);
	return $x;
    } else {
	my $grid = ral_grid_focal_count_of_grid($self->{GRID}, $mask, $value);
	if (defined wantarray) {
	    $grid = new Geo::Raster($grid);
	    return $grid;
	} else {
	    ral_grid_destroy($self->{GRID});
	    $self->{GRID} = $grid;
	}
    }
}

## @method @focal_range(listref mask, @cell)
#
# @brief Compute the focal range for the given cell.
# @param[in] mask The focal area defined as a 2D anonymous integer
# array. The width and height of the array must be 2d+1, where d is
# the max horizontal and vertical distance from the central cell.
# @param[in] cell The cell for which the range is computed.
# @return the range in an array (min, max).
sub focal_range {
    my($self, $mask, $i, $j) = @_;
    my $x = ral_grid_focal_range($self->{GRID}, $i, $j, $mask);
    return @$x;
}

sub spread {
    my($self, $mask) = @_;
    my $grid = ral_grid_spread($self->{GRID}, $mask);
    if (defined wantarray) {
	$grid = new Geo::Raster($grid);
	return $grid;
    } else {
	ral_grid_destroy($self->{GRID});
	$self->{GRID} = $grid;
    }
}

sub spread_random {
    my($self, $mask) = @_;
    my $grid = ral_grid_spread_random($self->{GRID}, $mask);
    if (defined wantarray) {
	$grid = new Geo::Raster($grid);
	return $grid;
    } else {
	ral_grid_destroy($self->{GRID});
	$self->{GRID} = $grid;
    }
}

1;
