package Geo::Raster;

## @class Geo::Raster
# @brief A class for geospatial rasters.
#
# Import tags:
# - \a logics Imports (overrides) \c not, \c and, and \c or
#
# This module should be discussed in https://list.hut.fi/mailman/listinfo/geo-perl
#
# The homepage of this module is 
# https://github.com/ajolma/geoinformatica.
#
# @author Ari Jolma
# @author Copyright (c) 1999- by Ari Jolma
# @author This library is free software; you can redistribute it and/or modify
# it according to the Artistic License 2.0.

=pod

=head1 NAME

Geo::Raster - Perl extension for geospatial rasters

The <a href="http://geoinformatics.aalto.fi/doc/Geoinformatica/html/">
documentation for Geo::Raster</a> is written in doxygen format.

=cut

use strict;
use warnings;
use Carp;
use POSIX;
POSIX::setlocale( &POSIX::LC_NUMERIC, "C" ); # http://www.gdal.org/faq.html nr. 12
use XSLoader;
use Scalar::Util 'blessed';
use Geo::GDAL;

# subsystems:
use Geo::Raster::Operations;
use Geo::Raster::Focal;
use Geo::Raster::Zonal;
use Geo::Raster::Global;
use Geo::Raster::IO;
use Geo::Raster::Image;
use Geo::Raster::Algorithms;
use Geo::Raster::TerrainAnalysis;
use Geo::Raster::Geostatistics;
use Geo::Raster::Layer; # requires Gtk2 and Gtk2::Ex::Geo

our $VERSION = '0.65';

# TODO: make these constants derived from libral:
our $INTEGER_GRID = 1;
our $REAL_GRID = 2;

require Exporter;

our @ISA = qw( Exporter );

our %EXPORT_TAGS = (types  => [ qw ( $INTEGER_GRID $REAL_GRID ) ],
		    logics => [ qw ( &not &and &or ) ] );

our @EXPORT_OK = qw ( $INTEGER_GRID $REAL_GRID
		      &not &and &or );

our $AUTOLOAD;

## @ignore
sub dl_load_flags {0x01}

XSLoader::load( 'Geo::Raster', $VERSION );

my %dispatch = (
    GetBandNumber =>  \&Geo::GDAL::Band::GetBandNumber,
    DataType =>  \&Geo::GDAL::Band::DataType,
    Size =>  \&Geo::GDAL::Band::Size,
    GetBlockSize =>  \&Geo::GDAL::Band::GetBlockSize,
    ColorInterpretation =>  \&Geo::GDAL::Band::ColorInterpretation,
    NoDataValue =>  \&Geo::GDAL::Band::NoDataValue,
    Unit =>  \&Geo::GDAL::Band::Unit,
    ScaleAndOffset =>  \&Geo::GDAL::Band::ScaleAndOffset,
    GetMinimum =>  \&Geo::GDAL::Band::GetMinimum,
    GetMaximum =>  \&Geo::GDAL::Band::GetMaximum,
    ComputeStatistics =>  \&Geo::GDAL::Band::ComputeStatistics,
    GetStatistics =>  \&Geo::GDAL::Band::GetStatistics,
    SetStatistics =>  \&Geo::GDAL::Band::SetStatistics,
    GetOverviewCount =>  \&Geo::GDAL::Band::GetOverviewCount,
    GetOverview =>  \&Geo::GDAL::Band::GetOverview,
    HasArbitraryOverviews =>  \&Geo::GDAL::Band::HasArbitraryOverviews,
    Checksum =>  \&Geo::GDAL::Band::Checksum,
    ComputeRasterMinMax =>  \&Geo::GDAL::Band::ComputeRasterMinMax,
    ComputeBandStats =>  \&Geo::GDAL::Band::ComputeBandStats,
    Fill =>  \&Geo::GDAL::Band::Fill,
    WriteTile =>  \&Geo::GDAL::Band::WriteTile,
    ReadTile =>  \&Geo::GDAL::Band::ReadTile,
    WriteRaster =>  \&Geo::GDAL::Band::WriteRaster,
    ReadRaster =>  \&Geo::GDAL::Band::ReadRaster,
    GetHistogram =>  \&Geo::GDAL::Band::GetHistogram,
    GetDefaultHistogram =>  \&Geo::GDAL::Band::GetDefaultHistogram,
    SetDefaultHistogram =>  \&Geo::GDAL::Band::SetDefaultHistogram,
    FlushCache =>  \&Geo::GDAL::Band::FlushCache,
    ColorTable =>  \&Geo::GDAL::Band::ColorTable,
    GetColorTable =>  \&Geo::GDAL::Band::GetColorTable,
    SetColorTable =>  \&Geo::GDAL::Band::SetColorTable,
    CreateMaskBand =>  \&Geo::GDAL::Band::CreateMaskBand,
    GetMaskBand =>  \&Geo::GDAL::Band::GetMaskBand,
    GetMaskFlags =>  \&Geo::GDAL::Band::GetMaskFlags,
    CategoryNames =>  \&Geo::GDAL::Band::CategoryNames,
    GetRasterCategoryNames =>  \&Geo::GDAL::Band::GetRasterCategoryNames,
    SetRasterCategoryNames =>  \&Geo::GDAL::Band::SetRasterCategoryNames,
    AttributeTable =>  \&Geo::GDAL::Band::AttributeTable,
    GetDefaultRAT =>  \&Geo::GDAL::Band::GetDefaultRAT,
    SetDefaultRAT =>  \&Geo::GDAL::Band::SetDefaultRAT,
    Contours =>  \&Geo::GDAL::Band::Contours,
    FillNodata =>  \&Geo::GDAL::Band::FillNodata,
    );

## @ignore
# call Geo::GDAL::Band methods as a fallback
sub AUTOLOAD {
    my $self = shift;
    (my $sub = $AUTOLOAD) =~ s/.*:://;
    if (exists $dispatch{$sub}) {
	unshift @_, $self->band();
	goto $dispatch{$sub};
    } else {
	croak "Undefined subroutine $sub";
    }
}

## @ignore
sub from_piddle {
    my($self, $pdl) = @_;
    $pdl->make_physical;
    my @dims = $pdl->dims;
    croak "pdl is not a 2D raster" unless @dims == 2;
    ral_grid_destroy($self->{GRID}) if $self->{GRID};
    my $type = $pdl->get_datatype;
    # should test against libral types
    my $grid;
    if ($type < 5) { # an integer type
	$self->{GRID} = ral_grid_create($INTEGER_GRID, $dims[1], $dims[0]);
    } else {
	$self->{GRID} = ral_grid_create($REAL_GRID, $dims[1], $dims[0]);
    }
    my $data = $pdl->get_dataref;
    pdl2grid($data, $type, $self->{GRID});
}

## @ignore
sub _new_grid {
    my($self, $grid) = @_;
    return unless $grid;
    ral_grid_destroy($self->{GRID}) if $self->{GRID};
    $self->{GRID} = $grid;
    _attributes($self);
}

## @ignore
sub _interpret_datatype {
    return $INTEGER_GRID if $_[0] =~  m/^i/i;
    return $REAL_GRID if $_[0] =~ m/^real/i;
    return $REAL_GRID if $_[0] =~ m/^float/i;
    return $INTEGER_GRID if $_[0] == $INTEGER_GRID;
    return $REAL_GRID if $_[0] == $REAL_GRID;
    return $INTEGER_GRID;
}

## @cmethod Geo::Raster new($filename)
#
# @brief Create a new raster from a file.
#
# @note
# The new raster is only an interface to a raster accessed by GDAL. To
# load data from GDAL to memory use the method Geo::Raster::IO::cache.
#
# Example:
# @code
# $raster = Geo::Raster->new("data/dem.bil");
# @endcode
# @param[in] filename Name of a raster file that is recognized by GDAL.
# @return a new raster.

## @cmethod Geo::Raster new($datatype, $rows, $columns)
#
# @brief Create a new raster.
#
# Example of creating a new floating point raster:
# @code
# $raster = Geo::Raster->new('real', 100, 100);
# @endcode
# Example of creating a new integer raster:
# @code
# $raster = Geo::Raster->new(100, 100);
# @endcode
#
# @param[in] datatype (optional) The datatype for the new raster,
# either "integer" or "real".  Default is integer.
# @param[in] rows Height of the new raster.
# @param[in] columns Width of the new raster.
# @return a new raster

## @cmethod Geo::Raster new(%params)
#
# @brief Create a new raster using named parameters.
#
# @param[in] params Named parameters:
# - \a datatype The data type for the new raster. Either "real" or
# "integer". Default is integer.
# - \a copy A raster to be copied into the new raster.
# - \a like A raster to be used as a model for the new raster (no data is copied).
# - \a filename Name of a raster file. GDAL is used for opening the file.
# - \a access Access mode for GDAL. Either 'ReadOnly' or 'Update'. Default is 'ReadOnly'.
# - \a band integer (optional) Which band to read from the file. Default is 1.
# - \a load boolean (optional) Whether to convert the GDAL raster
# into a libral raster. Default is false.
# - \a rows Height of the new raster.
# - \a columns Width of the new raster.
# - \a world Named parameters suitable to define the real world boundaries. 
# Used only if \a rows and \a columns are also given. Possible parameters 
# include:
#   - cell_size
#   - minx
#   - miny
#   - maxx
#   - maxy
# @return a new raster.
# @exception The cells of the raster in a file are not squares.
# @exception The orientation of the raster in a file is not strictly north up.
# @todo Take GDAL into account in copying.
sub new {
    my $package = shift;
    my %params;

    if (@_ == 1 and ref($_[0]) eq 'ral_gridPtr') {
	
	$params{use} = shift;
	
    } elsif (@_ == 1 and blessed($_[0]) and $_[0]->isa('Geo::Raster')) { # Geo::Raster->new($raster)
	
	$params{copy} = shift;
	
    } elsif (@_ == 1 and ref($_[0]) eq 'PDL') {
	
	$params{piddle} = shift;
	
    } elsif (@_ == 1) {
	
	$params{filename} = shift;
	
    } elsif (@_ == 2 and ($_[0] =~ /\d+/) and ($_[1] =~ /\d+/)) {
	
	$params{M} = shift;
	$params{N} = shift;
	$params{datatype} = $INTEGER_GRID;
	
    } elsif (@_ == 3) {
	
	$params{datatype} = shift;
	$params{M} = shift;
	$params{N} = shift;

    }

    if (@_) {
	my %p = @_;
	for (keys %p) {
	    $params{$_} = $p{$_} unless exists $params{$_};
	}
	$params{M} = $params{rows} if exists $params{rows};
	$params{N} = $params{columns} if exists $params{columns};
    }

    my $self = {};
    bless $self => (ref($package) or $package);

    $self->{TABLE} = [];
    
    $params{datatype} = $params{datatype} ? _interpret_datatype($params{datatype}) : 0;
    
    if (blessed($params{copy}) and $params{copy}->isa('Geo::Raster')) {
	croak "Can't copy an empty raster." unless $params{copy}->{GRID};
	$self->{GRID} = ral_grid_create_copy($params{copy}->{GRID}, $params{datatype})
    } elsif ($params{use} and ref($params{use}) eq 'ral_gridPtr') {
	$self->{GRID} = $params{use};
    } elsif (defined $params{piddle}) {
	from_piddle($self, $params{piddle});
    } elsif (defined $params{like}) {
	$self->{GRID} = ral_grid_create_like($params{like}->{GRID}, $params{datatype});
    } elsif ($params{filename}) {
	gdal_open($self, %params);
	$self->{FILENAME} = $params{filename};
    } elsif ($params{M} and $params{N}) {
	$params{datatype} = $INTEGER_GRID unless $params{datatype};
	$self->{GRID} = ral_grid_create($params{datatype}, $params{M}, $params{N});
	if ($params{world}) {
	    ref $params{world} eq 'HASH' ? 
		$self->world( %{$params{world}} ) :
		$self->world( minx=>$params{world}->[0], 
			      miny=>$params{world}->[1],
			      maxx=>$params{world}->[2] );
	}
    }
    $self->_attributes() if $self->{GRID};
    return $self;
}

sub height {
    ral_grid_get_height($_[0]->{GRID})
}

sub width {
    ral_grid_get_width($_[0]->{GRID})
}

## @ignore
sub DESTROY {
    my $self = shift;
    return unless $self;
    ral_grid_destroy($self->{GRID}) if $self->{GRID} and ref($self->{GRID}) eq 'ral_gridPtr';
    delete($self->{GRID});
}

## @ignore
sub _with_decimal_point {
    my $tmp = shift;
    $tmp =~ s/,/./;
    return $tmp;
}

## @method @bounding_box(%params)
# 
# @brief Get or set the bounding box.
# @param[in] params Named parameters:
# - \a min_x The min x of the bounding box.
# - \a min_y The min y of the bounding box.
# - \a max_x The max x of the bounding box.
# - \a max_y The max y of the bounding box.
# - \a cell_size Length of the edges of the cells.
# if there is one.
# @note At least three parameters are needed to define the bounding box.
# @return (min_x, min_y, max_x, max_y) if possible
sub world {
    my $self = shift;
    if (@_) {
	my($cell_size,$minx,$miny,$maxx,$maxy);
	my %o = @_;
	for (keys %o) {
	    my $k = $_;
	    s/_//g;
	    $cell_size = $o{$k} if /cellsize/i;
	    $minx = $o{$k} if /minx/i;
	    $miny = $o{$k} if /miny/i;
	    $maxx = $o{$k} if /maxx/i;
	    $maxy = $o{$k} if /maxy/i;
	}
	if ($cell_size and defined($minx) and defined($miny)) {
	    ral_grid_set_bounds_csnn($self->{GRID}, $cell_size, $minx, $miny);
	} elsif ($cell_size and defined($minx) and defined($maxy)) {
	    ral_grid_set_bounds_csnx($self->{GRID}, $cell_size, $minx, $maxy);
	} elsif ($cell_size and defined($maxx) and defined($miny)) {
	    ral_grid_set_bounds_csxn($self->{GRID}, $cell_size, $maxx, $miny);
	} elsif ($cell_size and defined($maxx) and defined($maxy)) {
	    ral_grid_set_bounds_csxx($self->{GRID}, $cell_size, $maxx, $maxy);
	} elsif (defined($minx) and defined($maxx) and defined($miny)) {
	    ral_grid_set_bounds_nxn($self->{GRID}, $minx, $maxx, $miny);
	} elsif (defined($minx) and defined($maxx) and defined($maxy)) {
	    ral_grid_set_bounds_nxx($self->{GRID}, $minx, $maxx, $maxy);
	} elsif (defined($minx) and defined($miny) and defined($maxy)) {
	    ral_grid_set_bounds_nnx($self->{GRID}, $minx, $miny, $maxy);
	} elsif (defined($maxx) and defined($miny) and defined($maxy)) {
	    ral_grid_set_bounds_xnx($self->{GRID}, $maxx, $miny, $maxy);
	}
    } elsif ($self->{GDAL}) {
	my $dataset = $self->{GDAL}->{dataset};
	my @t = $dataset->GeoTransform();
	my $h = $dataset->{RasterYSize};
	my $w = $dataset->{RasterXSize};
	my $min_x = $t[1] > 0 ? $t[0] : $t[0]+$w*$t[1];
	my $max_x = $t[1] > 0 ? $t[0]+$w*$t[1] : $t[0];
	my $min_y = $t[5] > 0 ? $t[3] : $t[3]+$h*$t[5];
	my $max_y = $t[5] > 0 ? $t[3]+$h*$t[5] : $t[3];
	return ($min_x, $min_y, $max_x, $max_y);
    } elsif (!$self->{GRID}) {
	return ();
    } else {
	my $w = ral_grid_get_world($self->{GRID});
	return @$w;
    }
    #$self->_attributes;
}

## @method overlayable(Geo::Raster other)
#
# @brief Test if two rasters are overlayable.
sub overlayable {
    my($self, $other) = @_;
    ral_grid_overlayable($self->{GRID}, $other->{GRID});
}

## @ignore
*bounding_box = *world;

## @method copy_world_to(Geo::Raster to)
#
# @brief The method copies the bounding box to the given raster.
# @param[out] to A raster to which the world is copied to.
# @note copy_world_to is a deprecated alias to copy_bounding_box_to
sub copy_bounding_box_to {
    my($self, $to) = @_;
    ral_grid_copy_bounds($self->{GRID}, $to->{GRID});
}


## @ignore
sub flip_horizontal {
    my($self) = @_;
    ral_grid_flip_horizontal($self->{GRID});
}

## @ignore
sub flip_vertical {
    my($self) = @_;
    ral_grid_flip_vertical($self->{GRID});
}

## @ignore
*copy_world_to = *copy_bounding_box_to;

## @method boolean cell_in(@cell)
#
# @brief Whether a cell is in this raster.
# @param[in] cell The cell.
# @return boolean value.
sub cell_in {
    my($self, @cell) = @_;
    return ($cell[0] >= 0 and $cell[0] < $self->{M} and 
	    $cell[1] >= 0 and $cell[1] < $self->{N})
}

## @method boolean point_in(@point)
#
# @brief Whether a point is in the bounding box of this raster.
# @param[in] point The point (x, y)
# @return boolean value.
sub point_in {
    my($self, @point) = @_;
    my $world = ral_grid_get_world($self->{GRID});
    return ($point[0] >= $world->[0] and 
	    $point[0] <= $world->[2] and 
	    $point[1] >= $world->[1] and 
	    $point[1] <= $world->[3])
}

## @method @g2w(@cell)
#
# @brief Convert cell coordinates to world coordinates.
# @param[in] cell The cell coordinates (row, column).
# @return The center point of the cell in world coordinates (x,y).
sub g2w {
    my($self, @cell) = @_;
    if ($self->{GDAL}) {
	my @t = $self->{GDAL}->{dataset}->GeoTransform;
	my $x = $t[0] + ($cell[1]+0.5)*$t[1];
	my $y = $t[3] - ($cell[0]+0.5)*$t[5];
	return ($x,$y);
    }
    my $point = ral_grid_cell2point( $self->{GRID}, @cell);
    return @$point;
}

## @method @w2g(@point)
#
# @brief Convert world coordinates to cell coordinates.
# @param[in] point World coordinates (x, y)
# @return The cell (row, column), which contains the point.
sub w2g {
    my($self, @point) = @_;
    if ($self->{GDAL}) {
	my @t = $self->{GDAL}->{dataset}->GeoTransform;
	$point[0] -= $t[0];
	$point[0] /= $t[1];
	$point[1] -= $t[3];
	$point[1] /= $t[5];
	return (POSIX::floor($point[1]),POSIX::floor($point[0]));
    }
    my $cell = ral_grid_point2cell($self->{GRID}, @point);
    return @$cell;
}

## @method @ga2wa(@ga)
#
# @brief Convert a region in this raster to a rectangle in world
# coordinates.
# @param[in] ga Region in this raster as an array (upper_row,
# left_column, lower_row, right_column).
# @return rectangle in world coordinates (x_min, y_min, x_max, y_max)
sub ga2wa {
    my($self, @ga) = @_;
    if ($self->{GDAL}) {
	my @min = $self->g2w($ga[0],$ga[3]);
	my @max = $self->g2w($ga[2],$ga[1]);
	return (@min,@max);
    }
    my $min = ral_grid_cell2point($self->{GRID}, $ga[0], $ga[3]);
    my $max = ral_grid_cell2point($self->{GRID}, $ga[2], $ga[1]);
    return (@$min,@$max);
}

## @method @wa2ga(@wa)
#
# @brief Convert a rectangle in world coordinates to a region in this
# raster.
# @param[in] wa The boundary coordinates of an raster as an array
# (x_min, y_min, x_max, y_max).
# @return region coordinates (upper_row, left_column, lower_row,
# right_column)
sub wa2ga {
    my($self, @wa) = @_;
    if ($self->{GDAL}) {
	my @ul = $self->w2g($wa[0],$wa[3]);
	my @lr = $self->w2g($wa[2],$wa[1]);
	return (@ul,@lr);
    }
    my $ul = ral_grid_point2cell($self->{GRID}, $wa[0], $wa[3]);
    my $lr = ral_grid_point2cell($self->{GRID}, $wa[2], $wa[1]);
    return (@$ul,@$lr);
}

## @method mask(Geo::Raster mask)
#
# @brief Set or remove the mask.
# @param[in] mask (optional). If mask is undef, the method removes the current 
# mask.
sub mask {
    my($self, $mask) = @_;
    $mask ? 
	ral_grid_set_mask($self->{GRID}, $mask->{GRID}) : 
	ral_grid_clear_mask($self->{GRID});
}

## @method void set(@cell, $value)
#
# @brief Set the value of a cell.
#
# Example of setting to single cell a new value:
# @code
# $a->set($i, $j, $value);
# @endcode
# Example of setting to single cell a \a nodata value:
# @code
# $a->set($i, $j);
# @endcode
#
# @param[in] cell (optional) the cell coordinates
# @param[in] value (optional) The value to set, which can be a number,
# "nodata" or a raster. Default is "nodata".
sub set {
    my($self, $i, $j, $value) = @_;
    croak "set: GRID is undefined" unless $self->{GRID};
    if (defined($j)) {
	if (!defined($value) or $value eq 'nodata') {
	    return ral_grid_set_nodata($self->{GRID}, $i, $j);
	}
	if (ref $value) {
	    ral_grid_set_focal($self->{GRID}, $i, $j, $value);
	} else {
	    return ral_grid_set($self->{GRID}, $i, $j, $value);
	}
    } else {
	if (ref($i)) {
	    if (blessed($i) and $i->isa('Geo::Raster') and $i->{GRID}) {
		return ral_grid_copy($self->{GRID}, $i->{GRID});
	    } else {
		croak "can't copy a ",ref($i)," onto a grid\n";
	    }
	}
	if (!defined($i) or $i eq 'nodata') {
	    return ral_grid_set_all_nodata($self->{GRID});
	}
	ral_grid_set_all($self->{GRID}, $i);
    }
}

## @method $get(@cell)
# 
# @brief Retrieve the value of a cell.
#
# If the cell has a nodata or out-of-world value undef is returned.
# @param[in] cell The cell coordinates
# @return Value of the cell.
sub get {
    my($self, $i, $j, $distance) = @_;
    return unless $self->{GRID};
    if ($self->{GDAL}) {
	my @point = $self->g2w($i, $j);
	my $cell = ral_grid_point2cell($self->{GRID}, @point);
	($i, $j) = @$cell;
    }
    unless (defined $distance) {
	return ral_grid_get($self->{GRID}, $i, $j);
    } else {
	return ral_grid_get_focal($self->{GRID}, $i, $j, $distance);
    }
}

## @method $cell(@cell, $value)
#
# @brief Set or get the value of a cell.
# @param[in] cell The cell coordinates
# @param[in] value (optional) The value to set. If no value if given then the 
# method returns the cells current value.
# @return The cells current value. Only returned if no value is given to the 
# method.
sub cell {
    my($self, $i, $j, $value) = @_;
    if ($self->{GDAL}) {
	my @point = $self->g2w($i, $j);
	if ($self->{GRID}) {
	    my $cell = ral_grid_point2cell($self->{GRID}, @point);
	    ($i, $j) = @$cell;
	}
    }
    if (defined $value) {
	croak "cell: GRID is undefined" unless $self->{GRID};
	if (!defined($value) or $value eq 'nodata') {
	    ral_grid_set_nodata($self->{GRID}, $i, $j);
	}
	ral_grid_set($self->{GRID}, $i, $j, $value);
    } else {
	return unless $self->{GRID};
	ral_grid_get($self->{GRID}, $i, $j);
    }
}

## @method $point($x, $y, $value)
#
# @brief Set or get the value of a cell, which contains a point.
# @param[in] x The x-coordinate inside the world.
# @param[in] y The y-coordinate inside the world.
# @param[in] value (optional) The value to set. If no value if given then the method 
# returns the cells current value.
# @return The cells current value in which the point is located. Only returned 
# if no value is given to the method.
sub point {
    my($self, $x, $y, $value) = @_;
   
    if (defined $value) {

	croak "point: GRID is undefined" unless $self->{GRID};

	my $cell = ral_grid_point2cell($self->{GRID}, $x, $y);

	if (!defined($value) or $value eq 'nodata') {
	    ral_grid_set_nodata($self->{GRID}, $cell->[0], $cell->[1]);
	}
	ral_grid_set($self->{GRID}, $cell->[0], $cell->[1], $value);

    } else {

	return unless $self->{GRID};

	my $cell = ral_grid_point2cell($self->{GRID}, $x, $y);
	ral_grid_get($self->{GRID}, $cell->[0], $cell->[1]);

    }
}

## @method Geo::Raster data()
# 
# @brief Return a raster indicating data and nodata cells.
#
# @return a raster, which has 1 in the cells that have values and 0 in
# nodata cells. In void context changes this raster.
sub data {
    my $self = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_data($self->{GRID});
    return $self if defined wantarray;
}

## @method $schema(hashref schema)
#
# @brief Returns the objects schema (table names and numbers).
# @param[in] schema If the schema is given, then the method does nothing!
# @return The current schema of the object.
# @todo Support to give to the object a new schema.
# @todo link with RATs in GDAL
sub schema {
    my($self, $schema) = @_;
    if ($schema) {
    	
    } else {
	$schema = { GeometryType => 'Polygon',
		    Fields => [ { Name => 'Cell value', Type => $self->_type_name() } ] };
	if ($self->{TABLE_NAMES}) {
	    for my $i (0..$#{$self->{TABLE_NAMES}}) {
		push @{$schema->{Fields}}, {
		    Name => $self->{TABLE_NAMES}->[$i],
		    Type => $self->{TABLE_TYPES}->[$i],
		}
	    }
	}
	return bless $schema, 'Gtk2::Ex::Geo::Schema';
    }
}

## @method $has_field($field_name)
#
# @brief Indicates whether the raster attribute table (RAT) contain the given field.
# @param[in] field_name Name of the field whose existence is checked.
# @return True if the raster has a field having the same name as the given 
# parameter, else returns false.
# @todo link with RATs in GDAL
sub has_field {
    my($self, $field_name) = @_;
    return 1 if $field_name eq 'Cell value';
    return 0 unless $self->{TABLE_NAMES} and @{$self->{TABLE_NAMES}};
    for my $name (@{$self->{TABLE_NAMES}}) {	
		return 1 if $name eq $field_name;
    }
    return 0;
}

## @method @table($table)
#
# @brief Get or set the raster attribute table.
#
# An attribute table is a table, whose keys are cell values, thus defined only 
# for integer rasters.
#
# @param[in] table (optional). Either a reference to an array or a file name.
# @return If no parameter is given, the subroutine returns the current attribute 
# table.
# @todo link with RATs in GDAL
sub table {
    my($self, $table) = @_;
    if (ref $table) {
	$self->{TABLE_NAMES} = 0;
	$self->{TABLE_TYPES} = 0;
	$self->{TABLE} = [];
	for my $record (@$table) {
	    $self->{TABLE_NAMES} = [@$record],next unless $self->{TABLE_NAMES};
	    $self->{TABLE_TYPES} = [@$record],next unless $self->{TABLE_TYPES};
	    push @{$self->{TABLE}}, [@$record];
	}
    } elsif (defined $table) {
	open(my $fh, '<', $table) or croak "can't read from $table: $!\n";
	$self->{TABLE_NAMES} = 0;
	$self->{TABLE_TYPES} = 0;
	$self->{TABLE} = [];
	while (<$fh>) {
	    next if /^#/;
	    my @record = split /\t/;
	    $self->{TABLE_NAMES} = [@record],next unless $self->{TABLE_NAMES};
	    $self->{TABLE_TYPES} = [@record],next unless $self->{TABLE_TYPES};
	    push @{$self->{TABLE}},\@record;
	}
	close($fh);
    } else {
	return $self->{TABLE};
    }
}

## @ignore
sub _type_name {
    my $self = shift;
    return undef unless $self->{DATATYPE}; # may happen if not cached
    return 'Integer' if $self->{DATATYPE} == $INTEGER_GRID;
    return 'Real' if $self->{DATATYPE} == $REAL_GRID;
    return undef;
}

## @method list value_range(%params)
#
# @brief Returns the minimum and maximum values of the raster.
# @param[in] params Named parameters:
# - \a field_name The attribute whose min and max values are looked up.
# @return array (min,max)
sub value_range {
    my $self = shift;
    my $field_name;
    my %param;
    if (@_ == 1) {
	$field_name = shift;
    } else {
	%param = @_;
	$field_name = $param{field_name};
    }
    if (defined $field_name and $field_name ne 'Cell value') {
	my $schema = $self->schema()->{$field_name};
	croak "value_range: field with name '$field_name' does not exist" unless defined $schema;
	croak "value_range: can't use value from field '$field_name' since its' type is '$schema->{TypeName}'"
	    unless $schema->{TypeName} eq 'Integer' or $schema->{TypeName} eq 'Real';
	my $field = $schema->{Number};
	my @range;
	for my $r (@{$self->{TABLE}}) {
	    my $value = $r->[$field];
	    $range[0] = defined $range[0] ? ($range[0] < $value ? $range[0] : $value) : $value;
	    $range[1] = defined $range[1] ? ($range[1] > $value ? $range[1] : $value) : $value;
	}
	return @range;
    } elsif ($self->{GDAL}) {
	my $band = $self->band;
	return($band->GetMinimum, $band->GetMaximum) if $band;
    }
    return () unless $self->{GRID};
    my $range = ral_grid_get_value_range($self->{GRID});
    return @$range;
}

## @ignore
sub _attributes {
    my $self = shift;
    return unless $self->{GRID};
    my $datatype = $self->{DATATYPE} = ral_grid_get_datatype($self->{GRID});
    my $M = $self->{M} = ral_grid_get_height($self->{GRID});
    my $N = $self->{N} = ral_grid_get_width($self->{GRID});
    my $cell_size = $self->{CELL_SIZE} = ral_grid_get_cell_size($self->{GRID});
    my $world = $self->{WORLD} = ral_grid_get_world($self->{GRID});
    my $nodata = $self->{NODATA} = ral_grid_get_nodata_value($self->{GRID});
    return($datatype, $M, $N, $cell_size, @$world, $nodata);
}

## @ignore
sub _datatype {
    ral_grid_get_datatype($_[0]->{GRID});
}

## @method $datatype()
#
# @brief Returns the datatype of the raster as a string.
# @return Name of type if the object has a raster. Type can be 'Integer'
# or 'Real'.
sub datatype {
    my $self = shift;
    if ($self->{GDAL} and $self->{GDAL}->{dataset}) {
	my $t = $self->{GDAL}->{dataset}->GetRasterBand($self->{GDAL}->{band})->DataType;
	return 'GDAL Complex Data Type' if $t =~ /^C/;
	return 'Integer' if $t eq 'Byte' or $t =~ /Int/;
	return 'Real' if $t =~ /Float/;
	return 'Unknown GDAL Data Type';
    }
    return unless $self->{GRID};
    $self->{DATATYPE} = ral_grid_get_datatype($self->{GRID});
    return 'Integer' if $self->{DATATYPE} == $INTEGER_GRID;
    return 'Real' if $self->{DATATYPE} == $REAL_GRID;
}

## @ignore
sub data_type {
    my $self = shift;
    return $self->datatype;
}

## @method @size()
#
# @brief Returns the size (height, width) of the raster.
#
# @return The size (height, width) of the raster or an empty list if
# no part of the GDAL raster has yet been cached.
sub size {
    my $self = shift;
    my($i, $j) = @_;
    if (defined($i) and defined($j) and ($i =~ /^\d+$/) and ($j =~ /^\d+$/)) {
	return ral_grid_zonesize($self->{GRID}, $i, $j);
    } else {
	my %o = @_;
	if ($self->{GDAL}) {
	    return ($self->{GDAL}->{dataset}->{RasterYSize}, 
		    $self->{GDAL}->{dataset}->{RasterXSize});
	} elsif (!$self->{GRID}) {
	    return ();
	} else {
	    return (ral_grid_get_height($self->{GRID}), ral_grid_get_width($self->{GRID}));
	}
    }
}

## @method $cell_size()
# 
# @brief Returns the cell size.
# @return Cell size, i.e., the length of the cell edge in raster scale.
sub cell_size {
    my($self, %o) = @_;
    if ($self->{GDAL}) {
	my @t = $self->{GDAL}->{dataset}->GeoTransform;
	return (CORE::abs($t[1]), CORE::abs($t[5]));
    } elsif (!$self->{GRID}) {
	return undef;
    } else {
	$self->{CELL_SIZE} = ral_grid_get_cell_size($self->{GRID});
	return $self->{CELL_SIZE};
    }
}

## @method $nodata_value($value)
#
# @brief Get or set the value used to denote nodata values. 
# @param[in] value (optional) Value that represents \a nodata in the raster.
# @return the value for nodata if called without parameter.
sub nodata_value {
    my $self = shift;
    my $nodata_value = shift;
    if (defined $nodata_value) {
	if ($nodata_value eq '') {
	    ral_grid_remove_nodata_value($self->{GRID});
	} else {
	    ral_grid_set_nodata_value($self->{GRID}, $nodata_value);
	}
    } else {
	if ($self->{GDAL}) {
	    my $band = $self->band();
	    $nodata_value = $band->GetNoDataValue() if $band;
	} else {
	    $nodata_value = ral_grid_get_nodata_value($self->{GRID});
	}
    }
    return $nodata_value;
}

## @method Geo::Raster min($param)
# 
# @brief Set each cell to the minimum of its value and the parameter
# value.
# 
# @param[in] param Number to compare with the raster cell values.
# @return A new raster. In void context changes this raster.

## @method Geo::Raster min(Geo::Raster second)
# 
# @brief Set each cell to the minimum of its value and the value of
# the respective cell in the parameter raster.
#
# @param[in] second A raster, whose values are compared the values of
# this raster.
# @return A new raster. In void context changes this raster.
sub min {
    my $self = shift;
    my $second = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_min_grid($self->{GRID}, $second->{GRID});
    } else {
	if (defined($second)) {
	    if (ral_grid_get_datatype($self->{GRID}) == $INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_min_integer($self->{GRID}, $second);
	    } else {
		ral_grid_min_real($self->{GRID}, $second);
	    }
	} else {
	    my $range = ral_grid_get_value_range($self->{GRID});
	    return $range->[0];
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster max($param)
# 
# @brief Set each cell to the maximum of its value and the parameter
# value.
# 
# @param[in] param Number to compare with the raster cell values.
# @return A new raster. In void context changes this raster.

## @method Geo::Raster max(Geo::Raster second)
# 
# @brief Set each cell to the maximum of its value and the value of
# the respective cell in the parameter raster.
#
# @param[in] second A raster, whose values are compared the values of
# this raster.
# @return A new raster. In void context changes this raster.
sub max {
    my $self = shift;
    my $second = shift;   
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_max_grid($self->{GRID}, $second->{GRID});
    } else {
	if (defined($second)) {
	    if (ral_grid_get_datatype($self->{GRID}) == $INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_max_integer($self->{GRID}, $second);
	    } else {
		ral_grid_max_real($self->{GRID}, $second);
	    }
	} else {
	    my $range = ral_grid_get_value_range($self->{GRID});
	    return $range->[1];
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster random()
# @brief Return a random part of values of the values of this raster.
# @return a new raster. In void context changes the values of this raster.
sub random {
    my $self = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_random($self->{GRID});
    return $self if defined wantarray;
}

## @method Geo::Raster cross(Geo::Raster b)
# 
# @brief Cross product of rasters.
#
# Creates a new Geo::Raster whose values represent distinct
# combinations of values of the two operand rasters. May be used as
# lvalue or in-place. The operand rasters must be integer rasters and
# the rasters must be overlayable.
# @code
# $c = $a->cross($b);
# $a->cross($b);
# @endcode
#
# If a has values A = a(1), ..., a(n) (a(i) < a(j) if i < j) and b has
# values B = b(1), ..., b(m) (b(i) < b(j) if i < j) then c will have
# max n * m distinct values. The values in c are i(b) + i(a)*n + 1,
# where i(a) is the index of the value of a in array A minus 1 and
# i(b) is the index of the value of b in array B minus 1. c will be
# nodata if either a or b is nodata.
#
# @param[in] b A reference to an another Geo::Raster object.
# @return A new raster if requested.
sub cross {
    my($a, $b) = @_;
    my $c = ral_grid_cross($a->{GRID}, $b->{GRID}); 
    return new Geo::Raster ($c) if defined wantarray;
    $a->_new_grid($c) if $c;
}

## @method Geo::Raster if(Geo::Raster b, Geo::Raster c)
# 
# @brief If...then statement construct for rasters.
#
# Example of usage:
# @code
# $a->if($b, $c);
# @endcode
# where $a and $b are rasters and $c can be a raster or a scalar. The
# effect of this subroutine is:
# @code
# for all cells k: if (b[k]) then a[k]=c[k]
# @endcode
#
# If a return value is requested:
# @code
# $d = $a->if($b, $c);
# @endcode
# @code
# for all cells k: if (b[k]) then d[k]=c[k] else d[k]=a[k]
# @endcode
#
# - If $c is a reference to a hash of key=>value pairs, where key is
# an integer and value is a number, then
# @code
# for all cells k and keys key: if (b[k]==key) then a[k]=c[key]
# @endcode
#
# @param[in] b Raster, whose values are used as boolean values.
# @param[in] c Value raster, reference to a hash, or value.
# @return a raster whose values are the results of the if
# statement. In void context changes the values of this raster.

## @method Geo::Raster if(Geo::Raster b, Geo::Raster c, Geo::Raster d)
# 
# @brief If...then...else statement construct for rasters.
#
# Example of usage:
# @code
# $a->if($b, $c, $d);
# @endcode
# where $a and $b are rasters and $c and $d can be a rasters or
# values. The effect of this subroutine is:
#
# @code
# for all cells k: if (b[k]) then a[k]=c[k] else a[k]=d[k]
# @endcode
#
# If a return value is requested:
# @code
# $e = $a->if($b, $c, $d);
# @endcode
# @code
# for all cells k: if (b[k]) then e[k]=c[k] else e[k]=d[k]
# @endcode
#
# - If $c and $d are references to hashes of key=>value pairs, where
# key is an integer and value is a number, then
# @code
# for all cells k and keys key: if (b[k]==key) then a[k]=c[key] else a[k]=d[key]
# @endcode
#
# @param[in] b Raster, whose values are used as boolean values.
# @param[in] c Value raster, reference to a hash, or value.
# @param[in] d Value raster, reference to a hash, or value.
# @return a raster whose values are the results of the if
# statement. In void context changes the values of this raster.
sub if {
    my $a = shift;
    my $b = shift;    
    my $c = shift;
    my $d = shift;
    $a = Geo::Raster->new($a) if defined wantarray;
    croak "usage $a->if($b, $c)" unless defined $c;
    if (ref($c)) {
	if (blessed($c) and $c->isa('Geo::Raster')) {
	    ral_grid_if_then_grid($b->{GRID}, $a->{GRID}, $c->{GRID});
	} elsif (ref($c) eq 'HASH') {
	    my(@k,@v);
	    foreach (keys %{$c}) {
		push @k, int($_);
		push @v, $c->{$_};
	    }
	    ral_grid_zonal_if_then_real($b->{GRID}, $a->{GRID}, \@k, \@v, $#k+1);
	} else {
	    croak("usage: $a->if($b, $c)");
	}
    } else {
	unless (defined $d) {
	    if (ral_grid_get_datatype($a->{GRID}) == $INTEGER_GRID and $c =~ /^-?\d+$/) {
		ral_grid_if_then_integer($b->{GRID}, $a->{GRID}, $c);
	    } else {
		ral_grid_if_then_real($b->{GRID}, $a->{GRID}, $c);
	    }
	} else {
	    if (ral_grid_get_datatype($a->{GRID}) == $INTEGER_GRID and $c =~ /^-?\d+$/) {
		ral_grid_if_then_else_integer($b->{GRID}, $a->{GRID}, $c, $d);
	    } else {
		ral_grid_if_then_else_real($b->{GRID}, $a->{GRID}, $c, $d);
	    }
	}
    }
    return $a if defined wantarray;
}

## @method Geo::Raster bufferzone($z, $w)
#
# @brief Creates buffer zones around cells having the given value
#
# Creates (or converts a raster to) a binary raster, where all cells
# within distance w of a cell (measured as pixels from cell center to cell center)
# having the value z will have value of 1, all other cells will
# have values of 0. 
# @param[in] z Denotes cell values for which the bufferzone is computed.
# @param[in] w Width of the bufferzone.
# @note Defined only for integer rasters.
sub bufferzone {
    my($self, $z, $w) = @_;
    croak "method usage: bufferzone($z, $w)" unless defined($w);
    if (defined wantarray) {
	my $g = new Geo::Raster(ral_grid_bufferzone($self->{GRID}, $z, $w));
	return $g;
    } else {
	$self->_new_grid(ral_grid_bufferzone($self->{GRID}, $z, $w));
    }
}

## @method Geo::Raster distances()
#
# @brief Computes and stores into nodata cells the distance
# (in world units) to the nearest data cell.
# @return If a return value is wanted, then the method returns a new raster with 
# values only in this rasters \a nodata cells having the distance
# to the nearest data cell. 
sub distances {
    my($self) = @_;
    if (defined wantarray) {
	my $g = new Geo::Raster(ral_grid_distances($self->{GRID}));
	return $g;
    } else {
	$self->_new_grid(ral_grid_distances($self->{GRID}));
    }
}

## @method Geo::Raster directions()
# 
# @brief Computes and stores into nodata cells the direction to the nearest 
# data cell into nodata cells.
# 
# Directions are given in radians and direction zero is to the direction of 
# x-axis, Pi/2 is to the direction of y-axis.
# @return If a return value is wanted, then the method returns a new raster, with 
# values only in this rasters \a nodata cells, having the direction
# to the nearest data cell. 
sub directions {
    my($self) = @_;
    if (defined wantarray) {
	my $g = new Geo::Raster(ral_grid_directions($self->{GRID}));
	return $g;
    } else {
	$self->_new_grid(ral_grid_directions($self->{GRID}));
    }
}

## @method Geo::Raster clip($i1, $j1, $i2, $j2)
# 
# @brief Clips a part of the raster according the given rectangle.
#
# Example of clipping a raster:
# @code
# $g2 = $g1->clip($i1, $j1, $i2, $j2);
# @endcode
# 
# @param[in] i1 Upper left corners i-coordinate of the rectangle to clip.
# @param[in] j1 Upper left corners j-coordinate of the rectangle to clip.
# @param[in] i2 Bottom right corners i-coordinate of the rectangle to clip.
# @param[in] j2 Bottom right corners j-coordinate of the rectangle to clip.
# @return If a return value is wanted, then the method returns a new raster with
# size defined by the parameters.

## @method Geo::Raster clip(Geo::Raster area_to_clip)
# 
# @brief Clips a part of the raster according the given rasters real 
# world boundaries.
#
# Example of clipping a raster:
# @code
# $g2 = $g1->clip($g3);
# @endcode
# The example clips from $g1 a piece which is overlayable with $g3. 
# If there is no lvalue, $g1 is clipped.
# 
# @param[in] area_to_clip A Geo::Raster, which defines the area to clip.
# @return If a return value is wanted, then the method returns a new raster with
# size defined by the parameter.
sub clip {
    my $self = shift;
    if (@_ == 4) {
	my($i1, $j1, $i2, $j2) = @_;
	if (defined wantarray) {
	    my $g = new Geo::Raster(ral_grid_clip($self->{GRID}, $i1, $j1, $i2, $j2));
	    return $g;
	} else {
	    $self->_new_grid(ral_grid_clip($self->{GRID}, $i1, $j1, $i2, $j2));
	}
    } else {
	my $gd = shift;
	return unless blessed($gd) and $gd->isa('Geo::Raster');
	my @a = $gd->_attributes;
	my($i1,$j1) = $self->w2g($a[4],$a[7]);
	my($i2,$j2) = ($i1+$a[1]-1,$j1+$a[2]-1);
	if (defined wantarray) {
	    my $g = new Geo::Raster(ral_grid_clip($self->{GRID}, $i1, $j1, $i2, $j2));
	    return $g;
	} else {
	    $self->_new_grid(ral_grid_clip($self->{GRID}, $i1, $j1, $i2, $j2));
	}
    }
}

## @method Geo::Raster join(Geo::Raster second)
# 
# @brief The method joins the two given rasters.
#
# - The upper and left world boundaries must must have equal values.
# - If both rasters are of type real, then the joined raster will have 
# real as type.
#
# Example of joining
# @code
# $g3 = $g1->join($g2);
# @endcode
#
# The joining is based on the world coordinates of the rasters. clip and
# join without assignment clip or join the original raster, so
# @code
# $a->clip($i1, $j1, $i2, $j2);
#
# $a->join($b);
# @endcode
#
# @param[in] second A raster to join to this raster. 
# @return If a return value is wanted, then the method returns a new raster.
# @exception The rasters have a different cell size.
sub join {
    my $self = shift;
    my $second = shift;
    if (defined wantarray) {
	my $g = new Geo::Raster(ral_grid_join($self->{GRID}, $second->{GRID}));
	return $g;
    } else {
	$self->_new_grid(ral_grid_join($self->{GRID}, $second->{GRID}));
    }
}

## @method void assign(Geo::Raster src)
#
# @brief Assigns the values from an another raster to this. 
#
# The values are looked up simply based on the center point of cell.
# 
# Example of assigning
# @code
# $dest->assign($src);
# @endcode
#
# @param[in] src Source raster from where the values looked up.
sub assign {
    my($dest, $src) = @_;
    ral_grid_pick($dest->{GRID}, $src->{GRID});
}

## @method void clip_to(Geo::Raster like)
#
# @brief Creates a raster like the given raster and assigns to that
# raster values from this raster.
#
# @param[in] like Raster that defines the window for the new raster.
# @return a new raster. In void context copies to this raster and
# discards the reference to a GDAL raster.
sub clip_to {
    my($self, $like) = @_;
    if ($self->{GDAL}) {
	$self->cache($like);
    }
    if (defined wantarray) {
	my $g = new Geo::Raster(like=>$like, datatype=>ral_grid_get_datatype($self->{GRID}));
	$g->assign($self);
	return $g;
    } else {
	my $g = ral_grid_create_like($like->{GRID}, ral_grid_get_datatype($self->{GRID}));
	ral_grid_pick($g, $self->{GRID});
	$self->_new_grid($g);
	delete $self->{GDAL} if $self->{GDAL};
    }
}

## @method listref array()
#
# @brief Creates a list of the rasters values.
#
# Example of making an array of data in a raster
# @code
# $aref = $a->array;
# @endcode
# where $aref is a reference to a list of references to arrays of cells and values:
#
# [[i0, j0, val0], [i1, j1, val1], [i2, j2, val2], ...].
#
# @return a reference to a list.
sub array {
    my($self) = @_;
    my $a = ral_grid2list($self->{GRID});
    return $a;
}

## @method listref histogram(listref bins)
#
# @brief Calculates the histogram values for the given bins.
#
# Example of calculating a histogram:
# @code
# $histogram = $gd->histogram(\@bins);
# @endcode
#
# @param[in] bins Reference to an array having the border values for the bins.
# @return Reference to an array having amount of cells falling to each bin.

## @method listref histogram($bins)
#
# @brief 
#
# Example of calculating a histogram, where all values plotted in to 10 equal 
# sized intervals:
# @code
# $histogram = $gd->histogram(10);
# @endcode
#
# @param[in] bins (optional) Amount of bins (disjoint categories). If not given 20 
# is used as bins amount. There is no "best" number of bins, and different bin 
# sizes can reveal different features of the data.
# @return Reference to an array having amount of cells falling to each bin.
sub histogram {
    my $self = shift;
    my $bins = shift;
    $bins = 20 unless $bins;
    my $a;
    if (ref($bins)) {
	$a = ral_grid_histogram($self->{GRID}, $bins, $#$bins+1);
	return @$a;
    } else {
	my $bins = int($bins);
	my ($minval,$maxval) = $self->value_range();
	my @bins;
	my $i;
	my $d = ($maxval-$minval)/$bins;
	$bins[0] = $minval + $d;
	for $i (1..$bins-2) {
	    $bins[$i] = $bins[$i-1]+$d;
	}
	$bins[$bins-1] = $maxval;
	my $counts = ral_grid_histogram($self->{GRID}, \@bins, $bins+1);
	# now, $$counts[$n] should be zero, right? 
	# (there are no values > maxval)
	unshift @bins, $minval;
	my $a = {};
	for $i (0..$bins-1) {
	    $a->{($bins[$i]+$bins[$i+1])/2} = $counts->[$i];
	}
	return $a;
    }
}

## @method hashref contents()
#
# @brief Returns the histogram of an integer raster in a hash.
#
# @return a reference to a hash with cell values as keys and
# cellcounts as values.
sub contents {
    my $self = shift;
    if (ral_grid_get_datatype($self->{GRID}) == $INTEGER_GRID) {
	return ral_grid_contents($self->{GRID});
    } else {
	my $c = $self->array();
	my %d;
	for my $c (@$c) {
	    $d{$c->[2]}++;
	}
	return \%d;
    }
}

## @method Geo::Raster function($fct)
#
# @brief Evaluates a function and assigns the result to cell.
#
# An example, which fills a raster using an arbitrary function of x and y:
# @code
# $a->function('2*$x+3*$y');
# @endcode
# The function 2x+3y is evaluated at each cell and the result is
# assigned to the cell.
#
# @param[in] fct A string, which defines function of x, y, z, i, j,
# etc. z is the current value in the cell and x, y, i, and j are
# coordinates.
# @return a new raster. In a void context changes this raster.
sub function {
    my($self, $fct) = @_;
    my(undef, $M, $N, $cell_size, $minX, $minY, $maxX, $maxY) = $self->_attributes();
    $self = Geo::Raster->new($self) if defined wantarray;
    my $y = $maxY-$cell_size/2;
    for my $i (0..$M-1) {
	my $x = $minX+$cell_size/2;
	for my $j (0..$N-1) {	    
	    my $z = $self->get($i, $j);
	    my $a = eval $fct;
	    $self->set($i, $j, $a);
	    $x += $cell_size;
	}
	$y -= $cell_size;
    }
    return $self if defined wantarray;
}

## @method Geo::Raster map(hashref map)
#
# @brief Reclassify an integer raster.
#
# Example of mapping values
# @code
# $b = $a->map(\%map);
# @endcode
# or
# @code
# $a->map(\%map);
# @endcode
# or, using an anonymous hash created on the fly,
# @code
# $a->map({1=>5,2=>3});
# @endcode
# Maps cell values (keys in the map) in raster \a a to respective
# values in map.  Works only for integer rasters.
#
# @param[in] map This is a reference to a hash of (key=>value)
# mappings.  The key may be '*' (denoting a default value) or an
# integer. The value is a new value for the cell. If the value is a
# real number (i.e., contains '.') the result will be a real valued
# raster.
# @return a new raster. In void context changes this raster.

## @method Geo::Raster map(@map)
#
# @brief Reclassify a raster.
#
# @param[in] map This is a reference to a list of of pairs of
# mappings.  The key may be '*' (denoting a default value), number, or
# a reference to a list denoting a value range: [min_value,
# max_value]. The value is a new value for the cell. If the value is a
# real number (i.e., contains '.') the result is a real valued raster.
# @return a new raster. In void context changes this raster.
sub map {
    my $self = shift;
    my @map;
    if (@_ == 1) {
	if (ref($_[0]) eq 'HASH') {
	    for (keys %{$_[0]}) {
		push @map, $_;
		push @map, $_[0]->{$_};
	    }
	} elsif (ref($_[0]) eq 'ARRAY') {
	    @map = @{$_[0]};
	} else {
	    croak "usage map(list) or map({list}), list is a list of pairs of mappings";
	}
    } else {
	@map = @_;
    }
    my $ext = 0;
    my $to_real = 0;
    my $i;
    for ($i = 0; $i < $#map; $i += 2) {
	if (ref($map[$i]) eq 'ARRAY' or $map[$i] eq '*') {
	    $ext = 1;
	}
	if ($map[$i+1] =~ /\./ or $map[$i+1] =~ /\,/) {
	    $ext = 1;
	    $to_real = 1;
	}
    }  
    if (ral_grid_get_datatype($self->{GRID}) == $INTEGER_GRID and $to_real) {
	my $grid = ral_grid_create_copy($self->{GRID}, $REAL_GRID);
	if (defined wantarray) {
	    $self = new Geo::Raster $grid;
	} else {
	    $self->_new_grid($grid);
	}
    } else {
	if (defined wantarray) {
	    $self = new Geo::Raster $self;
	}
    }
    if ($ext) {
	my %map;
	my $default;
	my(@source_min, @source_max, @destiny);
	for ($i = 0; $i < $#map; $i += 2) {
	    if ($map[$i] eq '*') {
		$default = $map[$i+1];
	    } elsif (ref($map[$i]) eq 'ARRAY') {
		$map{$map[$i]->[0]}{max} = $map[$i]->[1];
		$map{$map[$i]->[0]}{to} = $map[$i+1];
	    } else {
		$map{$map[$i]}{max} = $map[$i]+1;
		$map{$map[$i]}{to} = $map[$i+1];
	    }
	}
	for my $min (sort {$a<=>$b} keys %map) {
	    push @source_min, $min;
	    push @source_max, $map{$min}{max};
	    push @destiny, $map{$min}{to};
	}
	my $n = @destiny;
	if (ral_grid_get_datatype($self->{GRID}) == $INTEGER_GRID) {
	    ral_grid_map_integer_grid($self->{GRID}, \@source_min, \@source_max, \@destiny, $n, $default);
	} else {
	    ral_grid_map_real_grid($self->{GRID}, \@source_min, \@source_max, \@destiny, $n, $default);
	}
    } else {
	my %map = @map;
	my(@source, @destiny);
	for (sort {$a<=>$b} keys %map) {
	    push @source, $_;
	    push @destiny, $map{$_};
	}
	my $n = @source;
	ral_grid_map($self->{GRID}, \@source, \@destiny, $n);
    }
    return $self if defined wantarray;
}

## @method hashref neighbors()
#
# @brief Compute a neighborhood hash for an integer raster.
#
# @return A reference to a hash of pairs (a=>b), where a is each cell
# value and \a b is a reference to a list of values that are found
# within the neighborhood of cells having the value \a a.
sub neighbors {
    my $self = shift;
    $a = ral_grid_neighbors($self->{GRID});
    return $a;
}

1;
__END__


=head1 SEE ALSO

Geo::GDAL

This module should be discussed in https://list.hut.fi/mailman/listinfo/geo-perl

The homepage of this module is
https://github.com/ajolma/geoinformatica

=head1 AUTHOR

Ari Jolma, ari.jolma _at_ aalto.fi

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1999- by Ari Jolma

This library is free software; you can redistribute it and/or modify
it according to the Artistic License 2.0.

=cut

