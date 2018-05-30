package Geo::GDAL::FFI::GeomFieldDefn;
use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = 0.05_03;

sub new {
    my ($class, $args) = @_;
    $args //= {};
    my $name = $args->{Name} // 'Unnamed';
    my $type = $args->{Type} // 'Point';
    my $tmp = $Geo::GDAL::FFI::geometry_types{$type};
    confess "Unknown geometry type: $type\n" unless defined $tmp;
    my $self = bless \Geo::GDAL::FFI::OGR_GFld_Create($name, $tmp), $class;
    $self->SetSpatialRef($args->{SpatialReference}) if $args->{SpatialReference};
    $self->SetNullable(0) if $args->{NotNullable};
    return $self;
}

sub DESTROY {
    my $self = shift;
    if ($Geo::GDAL::FFI::immutable{$$self}) {
        $Geo::GDAL::FFI::immutable{$$self}--;
        delete $Geo::GDAL::FFI::immutable{$$self} if $Geo::GDAL::FFI::immutable{$$self} == 0;
    } else {
        Geo::GDAL::FFI::OGR_GFld_Destroy($$self);
    }
}

sub GetSchema {
    my $self = shift;
    my $schema = {
        Name => $self->GetName,
        Type => $self->GetType
    };
    if (my $sr = $self->GetSpatialRef) {
        $schema->{SpatialReference} = $sr->Export('Wkt');
    }
    $schema->{NotNullable} = 1 unless $self->IsNullable;
    return $schema;
}

sub SetName {
    my ($self, $name) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $name //= '';
    Geo::GDAL::FFI::OGR_GFld_SetName($$self, $name);
}

sub GetName {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_GFld_GetNameRef($$self);
}

sub SetType {
    my ($self, $type) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $type //= 'Point';
    my $tmp = $Geo::GDAL::FFI::geometry_types{$type};
    confess "Unknown geometry type: $type\n" unless defined $tmp;
    $type = $tmp;
    Geo::GDAL::FFI::OGR_GFld_SetType($$self, $type);
}

sub GetType {
    my ($self) = @_;
    return $Geo::GDAL::FFI::geometry_types_reverse{Geo::GDAL::FFI::OGR_GFld_GetType($$self)};
}

sub SetSpatialRef {
    my ($self, $sr) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $sr = Geo::GDAL::FFI::SpatialReference->new($sr) unless ref $sr;
    Geo::GDAL::FFI::OGR_GFld_SetSpatialRef($$self, $$sr);
}

sub GetSpatialRef {
    my ($self) = @_;
    my $sr = Geo::GDAL::FFI::OGR_GFld_GetSpatialRef($$self);
    return bless \$sr, 'Geo::GDAL::FFI::SpatialReference' if $sr;
}

sub SetIgnored {
    my ($self, $ignored) = @_;
    #confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $ignored //= 1;
    Geo::GDAL::FFI::OGR_GFld_SetIgnored($$self, $ignored);
}

sub IsIgnored {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_GFld_IsIgnored($$self);
}

sub SetNullable {
    my ($self, $nullable) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $nullable //= 0;
    Geo::GDAL::FFI::OGR_GFld_SetNullable($$self, $nullable);
}

sub IsNullable {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_GFld_IsNullable($$self);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::GeomFieldDefn - A spatial field in a GDAL feature schema

=head1 SYNOPSIS

=head1 DESCRIPTION

There should not usually be any reason to directly access this method
except for the ignore methods. This object is created/read from/to the
Perl data structure in the CreateLayer method of a dataset, or in the
constructor or schema method of FeatureDefn.

The schema of a GeomFieldDefn is (Name, Type, SpatialReference,
NotNullable).

=head1 METHODS

=head2 SetIgnored

 $defn->SetIgnored($arg);

Ignore this field when reading features from a layer. To not ignore
this field call this method with defined but false (0) argument.

=head2 IsIgnored

Is this field ignored when reading features from a layer.

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
