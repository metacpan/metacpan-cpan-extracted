package Geo::GDAL::FFI::Driver;
use v5.10;
use strict;
use warnings;
use Carp;
use base 'Geo::GDAL::FFI::Object';

our $VERSION = 0.05_01;

sub GetName {
    my $self = shift;
    return $self->GetDescription;
}

sub Create {
    my ($self, $name, $args, $h) = @_;
    $name //= '';
    $args //= {};
    $args = {Width => $args, Height => $h} unless ref $args;
    my $o = 0;
    for my $key (keys %{$args->{Options}}) {
        $o = Geo::GDAL::FFI::CSLAddString($o, "$key=$args->{Options}{$key}");
    }
    my $ds;
    if (exists $args->{Source}) {
        my $src = ${$args->{Source}};
        my $s = $args->{Strict} // 0;
        my $ffi = FFI::Platypus->new;
        my $p = $ffi->closure($args->{Progress});
        $ds = Geo::GDAL::FFI::GDALCreateCopy($$self, $name, $src, $s, $o, $p, $args->{ProgressData});
    } elsif (not $args->{Width}) {
        $ds = Geo::GDAL::FFI::GDALCreate($$self, $name, 0, 0, 0, 0, $o);
    } else {
        my $w = $args->{Width};
        $h //= $args->{Height} // $w;
        my $b = $args->{Bands} // 1;
        my $dt = $args->{DataType} // 'Byte';
        my $tmp = $Geo::GDAL::FFI::data_types{$dt};
        confess "Unknown constant: $dt\n" unless defined $tmp;
        $ds = Geo::GDAL::FFI::GDALCreate($$self, $name, $w, $h, $b, $tmp, $o);
    }
    my $msg = Geo::GDAL::FFI::error_msg();
    if (!$ds || $msg) {
        $msg //= "Dataset '$name' creation failed. (Driver = ".$self->Name.")";
        confess $msg;
    }
    return bless \$ds, 'Geo::GDAL::FFI::Dataset';
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Driver - A GDAL data access driver

=head1 SYNOPSIS

=head1 DESCRIPTION

A format driver. Use the Driver method of a Geo::GDAL::FFI object to
obtain one.

=head1 METHODS

=head2 GetName

 my $name = $driver->GetName;

Returns the name of the driver.

=head2 Create

 my $name = $driver->Create($name, {Width => 100, ...});

Create a dataset. $name is the name for the dataset to create. Named
arguments are the following.

=over 4

=item C<Width>

Optional, but required to create a raster dataset.

=item C<Height>

Optional, default is the same as width.

=item C<Bands>

Optional, the number of raster bands in the dataset, default is one.

=item C<DataType>

Optional, the data type (a string) for the raster cells, default is
'Byte'.

=item C<Source>

Optional, the dataset to copy.

=item C<Progress>

Optional, used only in dataset copy, a reference to a subroutine.

=item C<ProgressData>

Optional, used only in dataset copy, a reference.

=item C<Strict>

Optional, used only in dataset copy, default is false (0).

=item C<Options>

Optional, driver specific creation options, default is reference to an
empty hash.

=back

 my $name = $driver->Create($name, $width);

A simple syntax for calling Create to create a raster dataset.

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
