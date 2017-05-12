## @class Geo::Raster::IO
# @brief Adds input/output methods into Geo::Raster
package Geo::Raster;

use strict;
use Config; # For byteorder
use Scalar::Util 'blessed';

## @ignore
# internal
sub gdal_open {
    my($self, %params) = @_;
    $params{access} = 'ReadOnly' unless $params{access};
    croak "gdal_open called with empty filename" if !(defined $params{filename}) or $params{filename} eq '';
    my $dataset = Geo::GDAL::Open($params{filename}, $params{access});
    croak "Geo::GDAL::Open failed for ".$params{filename} unless $dataset;
    my $t = $dataset->GetGeoTransform;
    unless ($t) {
		@$t = (0,1,0,0,0,1);
    }
    croak "The raster is not a strict north up image."
	unless $t->[2] == $t->[4] and $t->[2] == 0;
    my $band = $params{band} || 1;
    $self->{GDAL}->{dataset} = $dataset;
    $self->{GDAL}->{band} = $band;
    if ($params{load}) {
	cache($self);
	delete $self->{GDAL};
    }
    return 1;
}

## @method Geo::GDAL::Dataset dataset()
#
# @brief Return a dataset object associated with the raster.
#
# @return the underlying GDAL dataset or, in the case of pure libral
# raster, create a GDAL memory dataset and return it.
sub dataset {
    my $self = shift;
    return $self->{GDAL}->{dataset} if $self->{GDAL};
    my @size = $self->size;
    my $datapointer = ral_pointer_to_data($self->{GRID});
    my $datatype = ral_data_element_type($self->{GRID});
    my $size = ral_sizeof_data_element($self->{GRID});
    my %gdal_type = (
	'short' => 'Int',
	'float' => 'Float',
	);
    my $ds = Geo::GDAL::Open(
	"MEM:::DATAPOINTER=$datapointer,".
	"PIXELS=$size[1],LINES=$size[0],DATATYPE=$gdal_type{$datatype}$size");
    my $world = ral_grid_get_world($self->{GRID});
    my $cell_size = ral_grid_get_cell_size($self->{GRID});
    $ds->SetGeoTransform([$world->[0], $cell_size, 0, $world->[3], 0, -$cell_size]);
    return $ds;
}

## @method Geo::GDAL::Band band()
#
# @brief Return a band object associated with the raster.
#
# @return the band from the underlying GDAL dataset that is used, or,
# in the case of pure libral raster, create a GDAL memory dataset and
# return the (only) band of it.
sub band {
    my $self = shift;
    if ($self->{GDAL}) {
	return unless $self->{GDAL}->{dataset};
	return $self->{GDAL}->{dataset}->GetRasterBand($self->{GDAL}->{band});
    }
    my $ds = $self->dataset();
    return $ds->Band(1);
}

## @method Geo::Raster cache($min_x, $min_y, $max_x, $max_y, $cell_size)
#
# @brief Creates a new grid from the GDAL source.
#
# - The created grid is returned as a new Geo::Raster object only if
# used as a lvalue, else the new grid replaces the old grid of this raster.
# - The given bounding box is clipped to the bounding box of the
# dataset. The resulting bounding box of the work raster is always
# adjusted to pixel boundaries of the dataset.
# - If the cell_size is not given, the cell_size of the dataset is used.
# - If the cell_size is specified, it is used if it is larger than the
# cell_size of the dataset.
#
# @param[in] min_x The western border of the datasets bounding box.
# @param[in] min_y The southern border of the datasets bounding box.
# @param[in] max_x The eastern border of the datasets bounding box.
# @param[in] max_y The northern border of the datasets bounding box.
# @param[in] cell_size Length of the border of the cells.
# @return Geo::Raster.
# @exception The raster object does not have a GDAL source.

## @method Geo::Raster cache(Geo::Raster model_grid)
#
# @brief Creates a new grid from the GDAL source.
#
# - Uses the other raster grids world (bounding box, cell_size).
# - Otherwise works as above.
#
# @param[in] model_grid A reference to an another Geo::Raster object, 
# which is used as a model for world boundaries and cell size.
# @return Geo::Raster.
# @exception The parameter is not a Geo::Raster object.

## @method Geo::Raster cache()
#
# @brief Creates a new grid from the GDAL source.
#
# - Uses the world and cell_size of the GDAL raster.
# - Otherwise works as above.
#
# @return Geo::Raster.
sub cache {
    my $self = shift;
    croak "no GDAL" unless $self->{GDAL};
    my $dataset = $self->{GDAL}->{dataset};
    my $clip;
    my $cell_size;
    if (defined $_[0]) {
	if (@_ == 1) { # use the given grid as a model
	    croak "usage: \$raster->cache(\$another_raster)" unless blessed($_[0]) and $_[0]->isa('Geo::Raster');
	    if ($_[0]->{GDAL}) {
		my $ds = $_[0]->{GDAL}->{dataset};
		my $h = $ds->{RasterYSize};
		my $w = $ds->{RasterXSize};
		my $t = $ds->GetGeoTransform;
		my $min_x = $t->[1] > 0 ? $t->[0] : $t->[0]+$w*$t->[1];
		my $max_x = $t->[1] > 0 ? $t->[0]+$w*$t->[1] : $t->[0];
		my $min_y = $t->[5] > 0 ? $t->[3] : $t->[3]+$h*$t->[5];
		my $max_y = $t->[5] > 0 ? $t->[3]+$h*$t->[5] : $t->[3];
		$clip = [$min_x, $min_y, $max_x, $max_y];
		$cell_size = CORE::abs($t->[1]);
	    } else {
		$clip = ral_grid_get_world($_[0]->{GRID}); 
		$cell_size = ral_grid_get_cell_size($_[0]->{GRID});
	    }
	} else {
	    $clip = [@_[0..3]];
	    if ($clip->[1] > $clip->[3]) { # cope with ul,dr
		my $tmp = $clip->[3];
		$clip->[3] = $clip->[1];
		$clip->[1] = $tmp;
	    }
	    my $t = $dataset->GetGeoTransform;
	    $cell_size = CORE::abs($t->[1]);
	    $cell_size = $_[4] if defined($_[4]) and $_[4] > $cell_size;
	}
    } else {
	my $h = $dataset->{RasterYSize};
	my $w = $dataset->{RasterXSize};
	my $t = $dataset->GetGeoTransform;
	my $min_x = $t->[1] > 0 ? $t->[0] : $t->[0]+$w*$t->[1];
	my $max_x = $t->[1] > 0 ? $t->[0]+$w*$t->[1] : $t->[0];
	my $min_y = $t->[5] > 0 ? $t->[3] : $t->[3]+$h*$t->[5];
	my $max_y = $t->[5] > 0 ? $t->[3]+$h*$t->[5] : $t->[3];
	$clip = [$min_x, $min_y, $max_x, $max_y];
	$cell_size = CORE::abs($t->[1]);
    }

    my $gd = ral_grid_create_using_GDAL($dataset, $self->{GDAL}->{band}, @$clip, $cell_size);
    
    #done in libral:
    #my $band = $dataset->GetRasterBand($self->{GDAL}->{band});
    #my $nodata_value = $band->GetNoDataValue;
    #if (defined $nodata_value and $nodata_value ne '') {
	#ral_grid_set_nodata_value($gd, $nodata_value);
    #}
    
    return Geo::Raster->new($gd) if defined wantarray; # return strictly Geo::Rasters

    ral_grid_destroy($self->{GRID}) if $self->{GRID};
    $self->{GRID} = $gd;
    _attributes($self);
}

## @fn boolean exists($filename)
#
# @brief Checks if save with the same filename would overwrite an existing file.
# @param[in] filename Name of file without the file type extension.
sub exists {
    my $filename = @_ == 2 ? $_[1] : $_[0]; # can be used also as object method
    # better safe than sorry:
    return -e "$filename.bil" or -e "$filename.BIL" or
	-e "$filename.hdr" or -e "$filename.HDR";
}

## @method void save($filename, $format)
#
# @brief Save libral raster into a pair of hdr and bil files.
#
# Only genuine libral rasters are saved, i.e, rasters, which are GDAL
# raster caches are not saved. Extensions .bil and .asc are chopped of
# from the filename, but the extension .asc may be used to force
# saving the raster as Arc/Info ASCII.
#
# @param[in] filename (optional) Filename for the data files. If not
# given then the method tries to use the name attribute of the grid.
# @param[in] format (optional). If given and contains Arc/Info ASCII, the grid 
# is saved as such.
# @exception The given filename is not valid, or the file does not open with 
# writing permissions.
sub save {
    my($self, $filename, $format) = @_;

    croak "Geo::Raster object not saved because it is a GDAL dataset."if $self->{GDAL};

    $filename = $self->name() unless defined $filename;
    croak "usage: \$grid->save(\$filename)" unless defined $filename;

    my $ext = '';
    $ext = $1 if $filename =~ /\.(\w+)$/;
    $filename =~ s/\.\w+$// if $ext eq 'bil' or $ext eq 'asc';

    if ($ext eq 'asc' or ($format and $format =~ /arc\/info ascii/i)) {
	ral_grid_save_ascii($self->{GRID}, "$filename.asc");
	return;
    }

    open(my $fh, '>', "$filename.hdr") or croak "can't write to $filename.hdr: $!\n";

    my($datatype, $M, $N, $cell_size, $minX, $maxX, $minY, $maxY, $nodata_value) = 
	$self->_attributes();

    # these depend on how libral is configured! lookup needed
    my $nbits = $datatype == $Geo::Raster::REAL_GRID ? 32 : 16;
    my $pt = $datatype == $Geo::Raster::REAL_GRID ? 'F' : 'S';
    my $byteorder = $Config{byteorder} == 4321 ? 'M' : 'I';

    print $fh "BYTEORDER     $byteorder\n";
    print $fh "LAYOUT      BIL\n";
    print $fh "NROWS         $M\n";
    print $fh "NCOLS         $N\n";
    print $fh "NBANDS        1\n";
    
    print $fh "PIXELTYPE     $pt\n";
    
    print $fh "NBITS         $nbits\n";
    my $rowbytes = $nbits/8*$N;
    print $fh "BANDROWBYTES         $rowbytes\n";
    print $fh "TOTALROWBYTES        $rowbytes\n";
    print $fh "BANDGAPBYTES         0\n";
    print $fh "NODATA        $nodata_value\n" if defined $nodata_value;
    $minX += $cell_size / 2;
    $maxY -= $cell_size / 2;
    print $fh "ULXMAP        ",_with_decimal_point($minX),"\n";
    print $fh "ULYMAP        ",_with_decimal_point($maxY),"\n";
    print $fh "XDIM          ",_with_decimal_point($cell_size),"\n";
    print $fh "YDIM          ",_with_decimal_point($cell_size),"\n";
    close($fh);
    ral_grid_write($self->{GRID}, $filename.'.bil');
}

## @method void print()
#
# @brief Prints the values of the raster grid into stdout.
sub print {
    my($self) = @_;
    ral_grid_print($self->{GRID});
}

## @method void dump($to)
#
# @brief Prints the data (but not metadata, like size or other attributes of the 
# grid) of the raster into a file or stdout.
# @param[in] to (optional). Filename or a filehandle.
# @exception The given filename is not valid, or the file does not open with 
# writing permissions.
sub dump {
    my($self, $to) = @_;
    my $close;
    if ($to) {
	unless (ref($to) eq 'GLOB' or (blessed($to) and $to->isa('FileHandle'))) {
	    open(my $fh, '>', $to) or croak "can't write to $to: $!";
	    $to = $fh;
	    $close = 1;
	}
    } else {
	$to = \*STDOUT;
    }
    my $points = $self->array();
    for my $point (@$points) {
	print $to "$point->[0], $point->[1], $point->[2]\n";
    }
    close($to) if $close;
}

## @method void restore($from)
#
# @brief Reads the data (but not metadata, like size or other attributes of the 
# grid) of the raster from a file or stdin.
# @param[in] from (optional) filename or a filehandle. If not given data is read 
# from stdin.
# @exception The given filename is not valid, or the file does not open.
sub restore {
    my($self, $from) = @_;
    my $close;
    if ($from) {
	unless (ref($from) eq 'GLOB' or (blessed($from) and $from->isa('FileHandle'))) {
	    open(my $fh, '<', $from) or croak "can't read from $from: $!";
	    $from = $fh;
	    $close = 1;
	}
    } else {
	$from = \*STDIN;
    }
    ral_grid_set_all($self->{GRID}, 0);
    while (<$from>) {
	my($i, $j, $x) = split(/,/);
	ral_grid_set($self->{GRID}, $i, $j, $x);
    }
    close($from) if $close;
}

## @method void save_as_image($filename, $type, listref option_keys, listref option_values)
#
# @brief Saves the grid as image (*.jpeg, *.png, *.tiff, *.ico or *.bmp).
#
# @param[in] filename A string containing the filename where the image is saved.
# @param[in] type Name of format of the image to create. 
# Supported are jpeg, png, tiff, ico and bmp.
# @param[in] option_keys (optional). Name of options to set. Can be used for passing metadata.
# @param[in] option_values (optional). Values for the named options.
sub save_as_image {
    my($self, $filename, $type, $option_keys, $option_values) = @_;
    my $b = ral_pixbuf_create_from_grid($self->{GRID});
    $self->render($b, 255);
    $option_keys = [] unless $option_keys;
    $option_values = [] unless $option_values;
    ral_pixbuf_save($b, $filename, $type, $option_keys, $option_values);
    ral_pixbuf_destroy($b);
}

1;
