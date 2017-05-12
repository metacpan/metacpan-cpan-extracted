## @class Geo::Raster::Zonal
# @brief Adds zonal operations into Geo::Raster.
package Geo::Raster;

use strict;
use Statistics::Descriptive;

## @method hashref zones(Geo::Raster zones)
#
# @brief Returns the values from the raster in a hash indexed by the
# zones.
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return A reference to a hash, which has the zone integers as keys
# and the zonal values in an anonymous array referenced by the hash
# values.
# @exception The zone raster is not an integer raster.
# @note The returned hash contains \b all values from the raster and thus
# may be very large.
sub zones {
    my($self, $zones) = @_;
    return ral_grid_zones($self->{GRID}, $zones->{GRID});
}

## @method $size(@cell)
#
# @brief Returns the number of cells in a zone identified by a cell.
#
# @param[in] cell Zone cell. Identifies the zone.
# @return The number of cells in the zone.

## @method hashref zonal_fct(Geo::Raster zones, $fct)
#
# @brief Calculates a statistic of zonal values.
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @param fct (string) a method supported by
# Statistics::Descriptive. Default is mean.
# @return a reference to a hash, which has the zone integers as keys
# and the statistics as values.
# @note Uses internally the zones method and may thus be slow and memory intensive.
sub zonal_fct {
    my($self, $zones, $fct) = @_;
    my $z = ral_grid_zones($self->{GRID}, $zones->{GRID});
    $fct = 'mean' unless $fct;
    my %m;
    for (keys %{$z}) {
    	# http://search.cpan.org/~colink/Statistics-Descriptive-2.6/Descriptive.pm
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@{$z->{$_}});
	$m{$_} = eval "\$stat->$fct();";
    }
    return \%m;
}

## @method hashref zonal_count(Geo::Raster zones)
#
# @brief Calculates the amount of cells in each zone.
#
# Example:
# @code
# $zonalcount = $a->zonal_count($zones);
# $count_at_zone_1 = $zonalcount->{1};
# @endcode
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return a reference to a hash that has as keys the zones and as
# values the number of cells, which have a defined value, within that zone.
sub zonal_count {
    my($self, $zones) = @_;
    return ral_grid_zonal_count($self->{GRID}, $zones->{GRID});
}

## @method hashref zonal_sum(Geo::Raster zones)
#
# @brief Calculates the sum of this rasters cells for each zone.
#
# Example of getting sum of values for each zone:
# @code
# $zonalsum = $a->zonal_sum($zones);
# @endcode
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return a reference to a hash that has as keys the zones and as
# values the sum of cells within that zone.
sub zonal_sum {
    my($self, $zones) = @_;
    return ral_grid_zonal_sum($self->{GRID}, $zones->{GRID});
}

## @method hashref zonal_min(Geo::Raster zones)
#
# @brief Calculates the minimum of this rasters cells for each zone.
#
# Example of getting smallest value for each zone:
# @code
# $zonalmin = $a->zonal_min($zones);
# @endcode
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return a reference to a hash that has as keys the zones and as
# values the minimum value within that zone.
sub zonal_min {
    my($self, $zones) = @_;
    return ral_grid_zonal_min($self->{GRID}, $zones->{GRID});
}

## @method hashref zonal_max(Geo::Raster zones)
#
# @brief Calculates the maximum of this rasters cells for each zone.
#
# Example of getting highest value for each zone:
# @code
# $zonalmax = $a->zonal_max($zones);
# @endcode
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return a reference to a hash that has as keys the zones and as
# values the maximum value within that zone.
sub zonal_max {
    my($self, $zones) = @_;
    return ral_grid_zonal_max($self->{GRID}, $zones->{GRID});
}

## @method hashref zonal_mean(Geo::Raster zones)
#
# @brief Calculates the mean of this rasters cells for each zone.
#
# Example of getting mean of all values for each zone:
# @code
# $zonalmean = $a->zonal_mean($zones);
# @endcode
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return a reference to a hash that has as keys the zones and as
# values the average value within that zone.
sub zonal_mean {
    my($self, $zones) = @_;
    return ral_grid_zonal_mean($self->{GRID}, $zones->{GRID});
}

## @method hashref zonal_variance(Geo::Raster zones)
#
# @brief Calculates the variance of this rasters cells for each zone.
#
# Example of getting variance of all values for each zone:
# @code
# $zonalvar = $a->zonal_variance($zones);
# @endcode
#
# @param[in] zones An integer raster. Each zone is defined by a unique
# integer.
# @return a reference to a hash that has as keys the zones and as
# values the variance of the values within that zone.
sub zonal_variance {
    my($self, $zones) = @_;
    return ral_grid_zonal_variance($self->{GRID}, $zones->{GRID});
}

## @ignore
# I'm not sure I understand what happens here
sub grow_zones {
    my($zones, $grow, $connectivity) = @_;
    $connectivity = 8 unless defined($connectivity);
    $zones = new Geo::Raster $zones if defined wantarray;
    ral_grid_grow_zones($zones->{GRID}, $grow->{GRID}, $connectivity);
    return $zones if defined wantarray;
}

1;
