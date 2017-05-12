## @class Geo::Raster::Geostatistics
# @brief Adds geostatistical methods into Geo::Raster
package Geo::Raster;

use strict;

## @method array variogram($max_lag, $lags)
#
# @brief Computes a variogram from the raster.
# @param[in] max_lag maximum distance to which the variogram is computed
# @param[in] lags the number of ranges of h used in computing the variogram
# @return a list of lists (h, y(h))
sub variogram {
    my($self, $max_lag, $lags) = @_;
    # todo defaults for max_lag and lags
    my $a = ral_grid_variogram($self->{GRID}, $max_lag, $lags);
    return $a;
}

1;
