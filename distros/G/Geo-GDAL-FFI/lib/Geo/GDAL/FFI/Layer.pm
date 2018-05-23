package Geo::GDAL::FFI::Layer;
use v5.10;
use strict;
use warnings;
use Carp;
use base 'Geo::GDAL::FFI::Object';

our $VERSION = 0.05_01;

sub DESTROY {
    my $self = shift;
    Geo::GDAL::FFI::OGR_L_SyncToDisk($$self);
    #say STDERR "delete parent $parent{$$self}";
    delete $Geo::GDAL::FFI::parent{$$self};
    #say STDERR "destroy $self";
}

sub GetDefn {
    my $self = shift;
    my $d = Geo::GDAL::FFI::OGR_L_GetLayerDefn($$self);
    return bless \$d, 'Geo::GDAL::FFI::FeatureDefn';
}

sub CreateField {
    my $self = shift;
    my $def = shift;
    unless (ref $def) {
        # name => type calling syntax
        my $name = $def;
        my $type = shift;
        $def = Geo::GDAL::FFI::FieldDefn->new({Name => $name, Type => $type})
    } elsif (ref $def eq 'HASH') {
        $def = Geo::GDAL::FFI::FieldDefn->new($def)
    }
    my $approx_ok = shift // 1;
    my $e = Geo::GDAL::FFI::OGR_L_CreateField($$self, $$def, $approx_ok);
    return unless $e;
    confess Geo::GDAL::FFI::error_msg({OGRerror => $e});
}

sub CreateGeomField {
    my $self = shift;
    my $def = shift;
    unless (ref $def) {
        # name => type calling syntax
        my $name = $def;
        my $type = shift;
        $def = Geo::GDAL::FFI::GeomFieldDefn->new({Name => $name, Type => $type});
    } elsif (ref $def eq 'HASH') {
        $def = Geo::GDAL::FFI::GeomFieldDefn->new($def)
    }
    my $approx_ok = shift // 1;
    my $e = Geo::GDAL::FFI::OGR_L_CreateGeomField($$self, $$def, $approx_ok);
    return unless $e;
    confess Geo::GDAL::FFI::error_msg({OGRerror => $e});
}

sub GetSpatialRef {
    my ($self) = @_;
    my $sr = Geo::GDAL::FFI::OGR_L_GetSpatialRef($$self);
    return unless $sr;
    return bless \$sr, 'Geo::GDAL::FFI::SpatialReference';
}

sub ResetReading {
    my $self = shift;
    Geo::GDAL::FFI::OGR_L_ResetReading($$self);
}

sub GetNextFeature {
    my $self = shift;
    my $f = Geo::GDAL::FFI::OGR_L_GetNextFeature($$self);
    return unless $f;
    return bless \$f, 'Geo::GDAL::FFI::Feature';
}

sub GetFeature {
    my ($self, $fid) = @_;
    my $f = Geo::GDAL::FFI::OGR_L_GetFeature($$self, $fid);
    confess unless $f;
    return bless \$f, 'Geo::GDAL::FFI::Feature';
}

sub SetFeature {
    my ($self, $f) = @_;
    Geo::GDAL::FFI::OGR_L_SetFeature($$self, $$f);
}

sub CreateFeature {
    my ($self, $f) = @_;
    my $e = Geo::GDAL::FFI::OGR_L_CreateFeature($$self, $$f);
    return $f unless $e;
}

sub DeleteFeature {
    my ($self, $fid) = @_;
    my $e = Geo::GDAL::FFI::OGR_L_DeleteFeature($$self, $fid);
    return unless $e;
    confess Geo::GDAL::FFI::error_msg({OGRerror => $e});
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Layer - A collection of vector features in GDAL

=head1 SYNOPSIS

=head1 DESCRIPTION

A set of (vector) features having a same schema (the same Defn
object). Obtain a layer object by the CreateLayer or GetLayer method
of a vector dataset object.

=head1 METHODS

=head2 GetDefn

 my $defn = $layer->GetDefn;

Returns the FeatureDefn object for this layer.

=head2 ResetReading

 $layer->ResetReading;

=head2 GetNextFeature

 my $feature = $layer->GetNextFeature;

=head2 GetFeature

 my $feature = $layer->GetFeature($fid);

=head2 SetFeature

 $layer->SetFeature($feature);

=head2 CreateFeature

 $layer->CreateFeature($feature);

=head2 DeleteFeature

 $layer->DeleteFeature($fid);

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
