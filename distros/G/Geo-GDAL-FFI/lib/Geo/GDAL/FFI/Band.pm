package Geo::GDAL::FFI::Band;
use v5.10;
use strict;
use warnings;
use Carp;
use FFI::Platypus::Buffer;

our $VERSION = 0.05_01;

sub DESTROY {
    my $self = shift;
    delete $Geo::GDAL::FFI::parent{$$self};
}

sub GetDataType {
    my $self = shift;
    return $Geo::GDAL::FFI::data_types_reverse{Geo::GDAL::FFI::GDALGetRasterDataType($$self)};
}

sub GetWidth {
    my $self = shift;
    Geo::GDAL::FFI::GDALGetRasterBandXSize($$self);
}

sub GetHeight {
    my $self = shift;
    Geo::GDAL::FFI::GDALGetRasterBandYSize($$self);
}

sub GetSize {
    my $self = shift;
    return (
        Geo::GDAL::FFI::GDALGetRasterBandXSize($$self),
        Geo::GDAL::FFI::GDALGetRasterBandYSize($$self)
        );
}

sub GetNoDataValue {
    my $self = shift;
    my $b = 0;
    my $v = Geo::GDAL::FFI::GDALGetRasterNoDataValue($$self, \$b);
    return unless $b;
    return $v;
}

sub SetNoDataValue {
    my $self = shift;
    unless (@_) {
        Geo::GDAL::FFI::GDALDeleteRasterNoDataValue($$self);
        return;
    }
    my $v = shift;
    my $e = Geo::GDAL::FFI::GDALSetRasterNoDataValue($$self, $v);
    return unless $e;
    confess Geo::GDAL::FFI::error_msg() // "SetNoDataValue not supported by the driver.";
}

sub GetBlockSize {
    my $self = shift;
    my ($w, $h);
    Geo::GDAL::FFI::GDALGetBlockSize($$self, \$w, \$h);
    return ($w, $h);
}

sub pack_char {
    my $t = shift;
    my $is_big_endian = unpack("h*", pack("s", 1)) =~ /01/; # from Programming Perl
    return ('C', 1) if $t == 1;
    return ($is_big_endian ? ('n', 2) : ('v', 2)) if $t == 2;
    return ('s', 2) if $t == 3;
    return ($is_big_endian ? ('N', 4) : ('V', 4)) if $t == 4;
    return ('l', 4) if $t == 5;
    return ('f', 4) if $t == 6;
    return ('d', 8) if $t == 7;
    # CInt16 => 8,
    # CInt32 => 9,
    # CFloat32 => 10,
    # CFloat64 => 11
}

sub Read {
    my ($self, $xoff, $yoff, $xsize, $ysize, $bufxsize, $bufysize) = @_;
    $xoff //= 0;
    $yoff //= 0;
    my $t = Geo::GDAL::FFI::GDALGetRasterDataType($$self);
    my $buf;
    my ($pc, $bytes_per_cell) = pack_char($t);
    my $w;
    $xsize //= Geo::GDAL::FFI::GDALGetRasterBandXSize($$self);
    $ysize //= Geo::GDAL::FFI::GDALGetRasterBandYSize($$self);
    $bufxsize //= $xsize;
    $bufysize //= $ysize;
    $w = $bufxsize * $bytes_per_cell;
    $buf = ' ' x ($bufysize * $w);
    my ($pointer, $size) = scalar_to_buffer $buf;
    Geo::GDAL::FFI::GDALRasterIO($$self, $Geo::GDAL::FFI::Read, $xoff, $yoff, $xsize, $ysize, $pointer, $bufxsize, $bufysize, $t, 0, 0);
    my $offset = 0;
    my @data;
    for my $y (0..$bufysize-1) {
        my @d = unpack($pc."[$bufxsize]", substr($buf, $offset, $w));
        push @data, \@d;
        $offset += $w;
    }
    return \@data;
}

sub ReadBlock {
    my ($self, $xoff, $yoff, $xsize, $ysize, $t) = @_;
    $xoff //= 0;
    $yoff //= 0;
    Geo::GDAL::FFI::GDALGetBlockSize($$self, \$xsize, \$ysize) unless defined $xsize;
    $t = Geo::GDAL::FFI::GDALGetRasterDataType($$self) unless defined $t;
    my $buf;
    my ($pc, $bytes_per_cell) = pack_char($t);
    my $w = $xsize * $bytes_per_cell;
    $buf = ' ' x ($ysize * $w);
    my ($pointer, $size) = scalar_to_buffer $buf;
    Geo::GDAL::FFI::GDALReadBlock($$self, $xoff, $yoff, $pointer);
    my $offset = 0;
    my @data;
    for my $y (0..$ysize-1) {
        my @d = unpack($pc."[$xsize]", substr($buf, $offset, $w));
        push @data, \@d;
        $offset += $w;
    }
    return \@data;
}

sub Write {
    my ($self, $data, $xoff, $yoff, $xsize, $ysize) = @_;
    $xoff //= 0;
    $yoff //= 0;
    my $bufxsize = @{$data->[0]};
    my $bufysize = @$data;
    $xsize //= $bufxsize;
    $ysize //= $bufysize;
    my $t = Geo::GDAL::FFI::GDALGetRasterDataType($$self);
    my ($pc, $bytes_per_cell) = pack_char($t);
    my $buf = '';
    for my $i (0..$bufysize-1) {
        $buf .= pack($pc."[$bufxsize]", @{$data->[$i]});
    }
    my ($pointer, $size) = scalar_to_buffer $buf;
    Geo::GDAL::FFI::GDALRasterIO($$self, $Geo::GDAL::FFI::Write, $xoff, $yoff, $xsize, $ysize, $pointer, $bufxsize, $bufysize, $t, 0, 0);
}

sub WriteBlock {
    my ($self, $data, $xoff, $yoff) = @_;
    my ($xsize, $ysize);
    Geo::GDAL::FFI::GDALGetBlockSize($$self, \$xsize, \$ysize);
    my $t = Geo::GDAL::FFI::GDALGetRasterDataType($$self);
    my ($pc, $bytes_per_cell) = pack_char($t);
    my $buf = '';
    for my $i (0..$ysize-1) {
        $buf .= pack($pc."[$xsize]", @{$data->[$i]});
    }
    my ($pointer, $size) = scalar_to_buffer $buf;
    Geo::GDAL::FFI::GDALWriteBlock($$self, $xoff, $yoff, $pointer);
}

sub GetColorInterpretation {
    my $self = shift;
    return $Geo::GDAL::FFI::color_interpretations_reverse{
        Geo::GDAL::FFI::GDALGetRasterColorInterpretation($$self)
    };
}

sub SetColorInterpretation {
    my ($self, $i) = @_;
    my $tmp = $Geo::GDAL::FFI::color_interpretations{$i};
    confess "Unknown color interpretation: $i\n" unless defined $tmp;
    $i = $tmp;
    Geo::GDAL::FFI::GDALSetRasterColorInterpretation($$self, $i);
}

sub GetColorTable {
    my $self = shift;
    my $ct = Geo::GDAL::FFI::GDALGetRasterColorTable($$self);
    return unless $ct;
    # color table is a table of [c1...c4]
    # the interpretation of colors is from next method
    my @table;
    for my $i (0..Geo::GDAL::FFI::GDALGetColorEntryCount($ct)-1) {
        my $c = Geo::GDAL::FFI::GDALGetColorEntry($ct, $i);
        push @table, $c;
    }
    return wantarray ? @table : \@table;
}

sub SetColorTable {
    my ($self, $table) = @_;
    my $ct = Geo::GDAL::FFI::GDALCreateColorTable();
    for my $i (0..$#$table) {
        Geo::GDAL::FFI::GDALSetColorEntry($ct, $i, $table->[$i]);
    }
    Geo::GDAL::FFI::GDALSetRasterColorTable($$self, $ct);
    Geo::GDAL::FFI::GDALDestroyColorTable($ct);
}

sub GetPiddle {
    my ($self, $xoff, $yoff, $xsize, $ysize, $xdim, $ydim, $alg) = @_;
    $xoff //= 0;
    $yoff //= 0;
    my ($w, $h) = $self->GetSize;
    $xsize //= $w - $xoff;
    $ysize //= $h - $yoff;
    my $t = Geo::GDAL::FFI::GDALGetRasterDataType($$self);
    my $pdl_t = $Geo::GDAL::FFI::data_type2pdl_data_type{$Geo::GDAL::FFI::data_types_reverse{$t}};
    confess "The Piddle data_type is unsuitable.\n" unless defined $pdl_t;
    $xdim //= $xsize;
    $ydim //= $ysize;
    $alg //= 'NearestNeighbour';
    my $tmp = $Geo::GDAL::FFI::resampling{$alg};
    confess "Unknown resampling scheme: $alg\n" unless defined $tmp;
    $alg = $tmp;
    my $bufxsize = $xsize;
    my $bufysize = $ysize;
    my ($pc, $bytes_per_cell) = pack_char($t);
    my $buf = ' ' x ($bufysize * $bufxsize * $bytes_per_cell);
    my ($pointer, $size) = scalar_to_buffer $buf;
    Geo::GDAL::FFI::GDALRasterIO($$self, $Geo::GDAL::FFI::Read, $xoff, $yoff, $xsize, $ysize, $pointer, $bufxsize, $bufysize, $t, 0, 0);
    my $pdl = PDL->new;
    $pdl->set_datatype($pdl_t);
    $pdl->setdims([$xdim, $ydim]);
    my $data = $pdl->get_dataref();
    # FIXME: see http://pdl.perl.org/PDLdocs/API.html how to wrap $buf into a piddle
    $$data = $buf;
    $pdl->upd_data;
    # FIXME: we want approximate equality since no data value can be very large floating point value
    my $bad = GetNoDataValue($self);
    return $pdl->setbadif($pdl == $bad) if defined $bad;
    return $pdl;
}

sub SetPiddle {
    my ($self, $pdl, $xoff, $yoff, $xsize, $ysize) = @_;
    $xoff //= 0;
    $yoff //= 0;
    my ($w, $h) = $self->GetSize;
    my $t = $Geo::GDAL::FFI::pdl_data_type2data_type{$pdl->get_datatype};
    confess "The Piddle data_type '".$pdl->get_datatype."' is unsuitable.\n" unless defined $t;
    $t = $Geo::GDAL::FFI::data_types{$t};
    my ($xdim, $ydim) = $pdl->dims();
    $xsize //= $xdim;
    $ysize //= $ydim;
    if ($xdim > $w - $xoff) {
        warn "Piddle too wide ($xdim) for this raster band (width = $w, offset = $xoff).";
        $xdim = $w - $xoff;
    }
    if ($ydim > $h - $yoff) {
        $ydim = $h - $yoff;
        warn "Piddle too tall ($ydim) for this raster band (height = $h, offset = $yoff).";
    }
    my $data = $pdl->get_dataref();
    my ($pointer, $size) = scalar_to_buffer $$data;
    Geo::GDAL::FFI::GDALRasterIO($$self, $Geo::GDAL::FFI::Write, $xoff, $yoff, $xsize, $ysize, $pointer, $xdim, $ydim, $t, 0, 0);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Band - A GDAL raster band

=head1 SYNOPSIS

=head1 DESCRIPTION

A band (channel) in a raster dataset. Use the Band method of a dataset
object to obtain a band object.

=head1 METHODS

=head2 GetDataType

 my $datatype = $band->GetDataType;

=head2 GetSize

 my @size = $band->GetSize;

=head2 GetBlockSize

 my @size = $band->GetBlockSize;

=head2 GetNoDataValue

 my $nodata = $band->GetNoDataValue;

=head2 SetNoDataValue

 $band->SetNoDataValue($value);

Calling the method without arguments deletes the nodata value.

 $band->SetNoDataValue;

=head2 Read

 my $data = $band->Read($xoff, $yoff, $xsize, $ysize, $bufxsize, $bufysize);

All arguments are optional. If no arguments are given, reads the whole
raster band into a 2D Perl array. The returned array is an array of
references to arrays of row values.

=head2 ReadBlock

 my $data = $band->ReadBlock($xoff, $yoff, @blocksize, $datatype);

Reads a block of data from the band and returns it as a Perl 2D
array. C<@blocksize> and C<$datatype> (an integer) are optional and
obtained from the GDAL raster object if not given.

=head2 Write

 $band->Write($data, $xoff, $yoff, $xsize, $ysize);

=head2 WriteBlock

 $band->WriteBlock($data, $xoff, $yoff);

=head2 SetPiddle

 $band->SetPiddle($pdl, $xoff, $yoff, $xsize, $ysize);

Read data from a piddle into this Band.

=head2 GetPiddle

 $band->GetPiddle($xoff, $yoff, $xsize, $ysize, $xdim, $ydim);

Read data from this Band into a piddle.

=head2 GetColorInterpretation

 my $ci = $band->GetColorInterpretation;

=head2 SetColorInterpretation

 $band->SetColorInterpretation($ci);

=head2 GetColorTable

 my $color_table = $band->GetColorTable;

Returns the color table as an array of arrays. The inner tables are
colors [c1...c4].

=head2 SetColorTable

 $band->GetColorTable($color_table);

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;
