package Geo::GDAL::FFI::Dataset;
use v5.10;
use strict;
use warnings;
use Carp;
use base 'Geo::GDAL::FFI::Object';

our $VERSION = 0.05_01;

sub DESTROY {
    my $self = shift;
    $self->FlushCache;
    #say STDERR "DESTROY $self";
    Geo::GDAL::FFI::GDALClose($$self);
}

sub GetName {
    my $self = shift;
    return $self->GetDescription;
}

sub FlushCache {
    my $self = shift;
    Geo::GDAL::FFI::GDALFlushCache($$self);
}

sub GetDriver {
    my $self = shift;
    my $dr = Geo::GDAL::FFI::GDALGetDatasetDriver($$self);
    return bless \$dr, 'Geo::GDAL::FFI::Driver';
}

sub GetInfo {
    my $self = shift;
    my $o = 0;
    for my $s (@_) {
        $o = Geo::GDAL::FFI::CSLAddString($o, $s);
    }
    my $io = Geo::GDAL::FFI::GDALInfoOptionsNew($o, 0);
    Geo::GDAL::FFI::CSLDestroy($o);
    my $info = Geo::GDAL::FFI::GDALInfo($$self, $io);
    Geo::GDAL::FFI::GDALInfoOptionsFree($io);
    return $info;
}

sub Translate {
    my $self = shift;
    my $path = shift;
    my $o = 0;
    for my $s (@_) {
        $o = Geo::GDAL::FFI::CSLAddString($o, $s);
    }
    my $io = Geo::GDAL::FFI::GDALTranslateOptionsNew($o, 0);
    Geo::GDAL::FFI::CSLDestroy($o);
    my $e = 0;
    my $ds = Geo::GDAL::FFI::GDALTranslate($path, $$self, $io, \$e);
    Geo::GDAL::FFI::GDALTranslateOptionsFree($io);
    return bless \$ds, 'Geo::GDAL::FFI::Dataset' if $ds && ($e == 0);
    my $msg = Geo::GDAL::FFI::error_msg() // 'Translate failed.';
    confess $msg;
}

sub GetWidth {
    my $self = shift;
    return Geo::GDAL::FFI::GDALGetRasterXSize($$self);
}

sub GetHeight {
    my $self = shift;
    return Geo::GDAL::FFI::GDALGetRasterYSize($$self);
}

sub GetSize {
    my $self = shift;
    return (
        Geo::GDAL::FFI::GDALGetRasterXSize($$self),
        Geo::GDAL::FFI::GDALGetRasterYSize($$self)
        );
}

sub GetProjectionString {
    my ($self) = @_;
    return Geo::GDAL::FFI::GDALGetProjectionRef($$self);
}

sub SetProjectionString {
    my ($self, $proj) = @_;
    my $e = Geo::GDAL::FFI::GDALSetProjection($$self, $proj);
    if ($e != 0) {
        confess Geo::GDAL::FFI::error_msg();
    }
}

sub GetGeoTransform {
    my ($self) = @_;
    my $t = [0,0,0,0,0,0];
    Geo::GDAL::FFI::GDALGetGeoTransform($$self, $t);
    return wantarray ? @$t : $t;
}

sub SetGeoTransform {
    my $self = shift;
    my $t = @_ > 1 ? [@_] : shift;
    Geo::GDAL::FFI::GDALSetGeoTransform($$self, $t);
}

sub GetBand {
    my ($self, $i) = @_;
    $i //= 1;
    my $b = Geo::GDAL::FFI::GDALGetRasterBand($$self, $i);
    $Geo::GDAL::FFI::parent{$b} = $self;
    return bless \$b, 'Geo::GDAL::FFI::Band';
}

sub GetBands {
    my $self = shift;
    my @bands;
    for my $i (1..Geo::GDAL::FFI::GDALGetRasterCount($$self)) {
        push @bands, $self->GetBand($i);
    }
    return @bands;
}

sub GetLayer {
    my ($self, $i) = @_;
    $i //= 0;
    my $l = Geo::GDAL::FFI::isint($i) ? Geo::GDAL::FFI::GDALDatasetGetLayer($$self, $i) :
        Geo::GDAL::FFI::GDALDatasetGetLayerByName($$self, $i);
    $Geo::GDAL::FFI::parent{$l} = $self;
    return bless \$l, 'Geo::GDAL::FFI::Layer';
}

sub CreateLayer {
    my ($self, $args) = @_;
    $args //= {};
    my $name = $args->{Name} // '';
    my ($gt, $sr);
    if (exists $args->{GeometryFields}) {
        $gt = $Geo::GDAL::FFI::geometry_types{None};
    } else {
        $gt = $args->{GeometryType} // 'Unknown';
        $gt = $Geo::GDAL::FFI::geometry_types{$gt};
        confess "Unknown geometry type: '$args->{GeometryType}'\n" unless defined $gt;
        $sr = Geo::GDAL::FFI::OSRClone(${$args->{SpatialReference}}) if exists $args->{SpatialReference};
    }
    my $o = 0;
    if (exists $args->{Options}) {
        for my $key (keys %{$args->{Options}}) {
            $o = Geo::GDAL::FFI::CSLAddString($o, "$key=$args->{Options}->{$key}");
        }
    }
    my $l = Geo::GDAL::FFI::GDALDatasetCreateLayer($$self, $name, $sr, $gt, $o);
    Geo::GDAL::FFI::OSRRelease($sr) if $sr;
    my $msg = Geo::GDAL::FFI::error_msg();
    confess $msg if $msg;
    $Geo::GDAL::FFI::parent{$l} = $self;
    my $layer = bless \$l, 'Geo::GDAL::FFI::Layer';
    if (exists $args->{Fields}) {
        for my $f (@{$args->{Fields}}) {
            $layer->CreateField($f);
        }
    }
    if (exists $args->{GeometryFields}) {
        for my $f (@{$args->{GeometryFields}}) {
            $layer->CreateGeomField($f);
        }
    }
    return $layer;
}

sub CopyLayer {
    my ($self, $layer, $name, $options) = @_;
    $name //= '';
    my $o = 0;
    for my $key (keys %$options) {
        $o = Geo::GDAL::FFI::CSLAddString($o, "$key=$options->{$key}");
    }
    my $l = Geo::GDAL::FFI::GDALDatasetCopyLayer($$self, $$layer, $name, $o);
    unless ($l) {
        my $msg = Geo::GDAL::FFI::error_msg() // "GDALDatasetCopyLayer failed.";
        confess $msg if $msg;
    }
    $Geo::GDAL::FFI::parent{$l} = $self;
    return bless \$l, 'Geo::GDAL::FFI::Layer';
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Dataset - A GDAL dataset

=head1 SYNOPSIS

=head1 DESCRIPTION

A collection of raster bands or vector layers. Obtain a dataset object
by opening it with the Open method of Geo::GDAL::FFI object or by
creating it with the Create method of a Driver object.

=head1 METHODS

=head2 GetDriver

 my $driver = $dataset->GetDriver;

=head2 GetInfo

 my $driver = $dataset->GetInfo(@options);

=head2 Translate

 my $target = $source->Translate($name, @options);

Convert a raster dataset into another raster dataset. $name is the
name of the target dataset. This is the same as the gdal_translate
command line program, so the options are the same. See
L<http://www.gdal.org/gdal_translate.html>.

=head2 GetWidth

 my $w = $dataset->GetWidth;

=head2 GetHeight

 my $h = $dataset->GetHeight;

=head2 GetSize

 my @size = $dataset->GetSize;

Returns the size (width, height) of the bands of this raster dataset.

=head2 GetBand

 my $band = $dataset->GetBand($i);

Get the ith (by default the first) band of a raster dataset.

=head2 GetBands

 my @bands = $dataset->GetBands;

Returns a list of Band objects representing the bands of this raster
dataset.

=head2 CreateLayer

 my $layer = $dataset->CreateLayer({Name => 'layer', ...});

Create a new vector layer into this vector dataset.

Named arguments are the following.

=over 4

=item C<Name>

Optional, string, default is ''.

=item C<GeometryType>

Optional, default is 'Unknown', the type of the first geometry field;
note: if type is 'None', the layer schema does not initially contain
any geometry fields.

=item C<SpatialReference>

Optional, a SpatialReference object, the spatial reference for the
first geometry field.

=item C<Options>

Optional, driver specific options in an anonymous hash.

=item C<Fields>

Optional, a reference to an array of Field objects or schemas, the
fields to create into the layer.

=item C<GeometryFields>

Optional, a reference to an array of GeometryField objects or schemas,
the geometry fields to create into the layer; note that if this
argument is defined then the arguments GeometryType and
SpatialReference are ignored.

=back

=head2 GetLayer

 my $layer = $dataset->GetLayer($name);

If $name is strictly an integer, then returns the (name-1)th layer in
the dataset, otherwise returns the layer whose name is $name. Without
arguments returns the first layer.

=head2 CopyLayer

 my $copy = $dataset->CopyLayer($layer, $name, {DST_SRSWKT => 'WKT of a SRS', ...});

Copies the given layer into this dataset using the name $name and
returns the new layer. The options hash is mostly driver specific.

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
