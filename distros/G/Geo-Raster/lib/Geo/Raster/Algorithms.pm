## @class Geo::Raster::Algorithms
# @brief Adds various algorithmic methods to Geo::Raster
package Geo::Raster;

use strict;
# use Geo::Vector but allow silent failure
# which is useful when testing Geo::Raster without Geo::Vector
# if Geo::Vector is not available polygonize will not work
eval {
    require Geo::Vector;
};

## @method Geo::Raster interpolate(%params)
#
# @brief Interpolate values for nodata cells.
#
# @param[in] params Named parameters:
# - <i>method</i> => string. At moment only 'nearest neighbor' is
# supported.
# @return a new raster. In void context changes this raster.
# @exception A unsupported method is specified.
# @todo Add more interpolation methods.
sub interpolate {
    my($self, %param) = @_;
    $param{method} = 'nearest neighbor' unless defined $param{method};
    $param{method} = 'nearest neighbor' if $param{method} eq 'nn';
    my $new;
    if ($param{method} eq 'nearest neighbor') {
	$new = ral_grid_nn($self->{GRID});
    } else {
	croak "interpolation method '$param{method}' not implemented\n";
    }
    if (defined wantarray) {
	return Geo::Raster->new($new);
    } else {
	ral_grid_destroy($self->{GRID});
	$self->{GRID} = $new;
    }
}

## @method Geo::Raster dijkstra(@cell)
#
# @brief Computes a cost-to-go raster for a given cost raster and a
# target cell.
#
# When this method is applied to a cost raster, the method computes
# the cost to travel to the target cell from each cell in the
# raster. If the cost at a cell is less than one, the cell cannot be
# a part of the optimal route to the target.
# @param[in] cell The target cell.
# @return a new raster. In void context changes this raster.
sub dijkstra {
    my($self, $i, $j) = @_;
    my $new = ral_grid_dijkstra($self->{GRID}, $i, $j);
    if (defined wantarray) {
	return Geo::Raster->new($new);
    } else {
	ral_grid_destroy($self->{GRID});
	$self->{GRID} = $new;
    }
}

## @method Geo::Raster colored_map()
#
# @brief Attempts to use the smallest possible number of integers for
# the zones in the raster.
# @return a new raster. In void context changes this raster.
sub colored_map {
    my $self = shift;
    my $n = $self->neighbors();
    my %map;
    $map{0} = 0;
    my $base;
    my %nn;
    foreach $base (sort {$a<=>$b} keys %{$n}) {
    	# Going trough each value (zone)
	next if $base == 0; # Zero values are already the smallest.
	my $m = 1;
	$map{$base} = $m unless defined($map{$base}); # The first gets a value 1.
	my $skip = $map{$base};
	# Going trough each neighbor of the value.
	foreach (@{$$n{$base}}) {
	    # Checking if the neighbor does not already exist in the map hash.
	    if (!defined($map{$_})) {
		$m++;
		$m++ if $m == $skip;
		$map{$_} = $m; # Giving the neighbor a higher value.
	    } elsif ($map{$_} == $skip) {
		# Redefining:
		$m++;
		$m++ if $m == $skip;
		my $m2 = $m;
		while ($nn{$m2}{$_}) {
		    # Some base -> $m2 and $_ is already a neighbor of $m2
		    $m2++;
		    $m2++ if $m2 == $skip;
		}
		$map{$_} = $m2;
	    }
	    $nn{$skip}{$_} = 1;
	}
    }
    if (defined wantarray) {
	return $self->map(\%map);
    } else {
	$self->map(\%map);
    }
}

## @method Geo::Raster applytempl(listref templ, $new_val)
#
# @brief Apply a modifying template on the raster.
#
# The "apply template" method is a generic method which is, e.g., used
# in the thinning algorithm.
#
# @code
# $a->applytempl(\@templ, $new_val);
# @endcode
#
# @param[in] templ The structuring template (or mask) to use
# A structuring template is an integer array [0..8] where 0
# and 1 mean a binary value and -1 is don't care.  The array is the 3x3
# neighborhood:<BR>
# 0 1 2<BR>
# 3 4 5<BR>
# 6 7 8
#
# The cell 4 is the center of the template. If the template matches a
# cell's neighborhood, the cell will get the given new value after all
# cells are tested. 
# @param[in] new_val (optional). New value to give to the center cell if the 
# template rules match the cell and its 8 neighbours. If not given, then 1 is 
# used to inform about match success.
# @return a new raster. In void context changes this raster.
sub applytempl {
    my($self, $templ, $new_val) = @_;
    croak "applytempl: too few values in the template" if $#$templ < 8;
    $new_val = 1 unless $new_val;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_apply_templ($self->{GRID}, $templ, $new_val);
    return $self if defined wantarray;
}

## @method Geo::Vector polygonize(%params)
#
# @brief Polygonizes the raster into a polygon OGR layer.
#
# @param[in] params Named parameters that go to the constructor of
# Geo::Vector. Uses Polygonize from GDAL.
#
# @return a new OGR layer wrapped into a Geo::Vector object.
sub polygonize {
    my ($self, %params) = @_;

    $params{pixel_value_field} = 'value' unless $params{pixel_value_field};

    my $vector;
    
    if ($params{vector}) {
	croak "Layer given as parameter does not contain field '$params{pixel_value_field}' for pixel values." 
	    unless $params{vector}->schema->field($params{pixel_value_field});
	$vector = $params{vector};
    } else {
	$params{geometry_type} = 'Polygon';
	delete $params{geometries};
	delete $params{features};
	$params{create} = 'polygonized' unless ($params{create} or $params{layer} or $params{open});	
	if ($params{schema}) {
	    my $found;
	    for my $field (@{$params{schema}{Fields}}) {
		$found = 1, last if $field->{Name} eq $params{pixel_value_field};
	    }
	    push @{$params{schema}{Fields}}, { Name => 'value', Type => 'Integer' } unless $found;
	}
	eval {
	    $vector = Geo::Vector->new(%params);
	};
	croak "$@" if $@;
    }

    my $dataset = $self->dataset;
    my $band = $dataset->Band(1);
    my $layer = $vector->{OGR}->{Layer};
    eval {
	Geo::GDAL::Polygonize($band, undef, $layer, $params{pixel_value_field}, $params{options}, $params{callback}, $params{callback_date});
	};
    croak "$@" if $@;

    return $vector;
}

## @method Geo::Raster ca_step(@k)
#
# @brief Perform a cellular automata step.
#
# @param[in] k Array defining the cellular automaton defining the
# values with which the cell neighbor and the cell is multiplied. The
# indexes of the array for the neighbors are:<BR>
# 8 1 2<BR>
# 7 0 3<BR>
# 6 5 4
#
# The new value for the cell is a k weighted sum of the neighborhood
# cell values.
#
# @return a new raster. In void context changes this raster.
sub ca_step {
    my($self, @k) = @_;
    if (defined wantarray) {
	my $g = new Geo::Raster(ral_ca_step($self->{GRID}, \@k));
	return $g;
    } else {
	$self->_new_grid(ral_ca_step($self->{GRID}, \@k));
    }
}

1;
