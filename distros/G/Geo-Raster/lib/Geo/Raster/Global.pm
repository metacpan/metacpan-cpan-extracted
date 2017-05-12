## @class Geo::Raster::Global
# @brief Adds global operations into Geo::Raster
package Geo::Raster;

use strict;

## @method void set($value)
#
# @brief Global set to a value.

## @method $min()
# 
# @brief Global minimum.

## @method $max()
# 
# @brief Global maximum.

## @method $count()
#
# @brief The number of cells with defined values.
# @return Returns the count of cells without <I>no data</I> values.
sub count {
    my $self = shift;
    return ral_grid_count($self->{GRID});
}

## @method $sum()
#
# @brief Global sum.
sub sum {
    my($self) = @_;
    return ral_grid_sum($self->{GRID});
}

## @method $mean()
#
# @brief Global mean.
sub mean {
    my $self = shift;
    return ral_grid_mean($self->{GRID});
}

## @method $variance()
#
# @brief Global variance.
sub variance {
    my $self = shift;
    return ral_grid_variance($self->{GRID});
}

1;
