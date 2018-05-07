package Geo::GDAL::FFI::FeatureDefn;
use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = 0.04;

sub new {
    my ($class, $args) = @_;
    $args //= {};
    my $name = $args->{Name} // '';
    my $self = bless \Geo::GDAL::FFI::OGR_FD_Create($name), $class;
    if (exists $args->{Fields}) {
        for my $field (@{$args->{Fields}}) {
            $self->AddField(Geo::GDAL::FFI::FieldDefn->new($field));
        }
    }
    if (exists $args->{GeometryFields}) {
        my $first = 1;
        for my $field (@{$args->{GeometryFields}}) {
            if ($first) {
                my $d = bless \Geo::GDAL::FFI::OGR_FD_GetGeomFieldDefn($$self, 0),
                'Geo::GDAL::FFI::GeomFieldDefn';
                $d->SetName($field->{Name}) if defined $field->{Name};
                $self->SetGeomType($field->{Type});
                $d->SetSpatialRef($field->{SpatialReference}) if $field->{SpatialReference};
                $d->SetNullable(0) if $field->{NotNullable};
                $first = 0;
            } else {
                $self->AddGeomField(Geo::GDAL::FFI::GeomFieldDefn->new($field));
            }
        }
    } else {
        $self->SetGeomType($args->{GeometryType});
    }
    $self->SetStyleIgnored if $args->{StyleIgnored};
    return $self;
}

sub DESTROY {
    my $self = shift;
    #Geo::GDAL::FFI::OGR_FD_Release($$self);
}

sub GetSchema {
    my $self = shift;
    my $schema = {Name => $self->GetName};
    for (my $i = 0; $i < Geo::GDAL::FFI::OGR_FD_GetFieldCount($$self); $i++) {
        push @{$schema->{Fields}}, $self->GetFieldDefn($i)->GetSchema;
    }
    for (my $i = 0; $i < Geo::GDAL::FFI::OGR_FD_GetGeomFieldCount($$self); $i++) {
        push @{$schema->{GeometryFields}}, $self->GetGeomFieldDefn($i)->GetSchema;
    }
    $schema->{StyleIgnored} = 1 if $self->IsStyleIgnored;
    return $schema;
}

sub GetName {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_FD_GetName($$self);
}

sub GetFieldDefn {
    my ($self, $fname) = @_;
    my $i = $fname // 0;
    $i = Geo::GDAL::FFI::OGR_FD_GetFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    my $d = Geo::GDAL::FFI::OGR_FD_GetFieldDefn($$self, $i);
    confess "No such field: $fname" unless $d;
    ++$Geo::GDAL::FFI::immutable{$d};
    return bless \$d, 'Geo::GDAL::FFI::FieldDefn';
}

sub GetFieldDefns {
    my $self = shift;
    my @retval;
    for my $i (0..Geo::GDAL::FFI::OGR_FD_GetFieldCount($$self)-1) {
        push @retval, $self->GetFieldDefn($i);
    }
    return @retval;
}

sub GetGeomFieldDefn {
    my ($self, $fname) = @_;
    my $i = $fname // 0;
    $i = Geo::GDAL::FFI::OGR_FD_GetGeomFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    my $d = Geo::GDAL::FFI::OGR_FD_GetGeomFieldDefn($$self, $i);
    confess "No such field: $fname" unless $d;
    ++$Geo::GDAL::FFI::immutable{$d};
    return bless \$d, 'Geo::GDAL::FFI::GeomFieldDefn';
}

sub GetGeomFieldDefns {
    my $self = shift;
    my @retval;
    for my $i (0..Geo::GDAL::FFI::OGR_FD_GetGeomFieldCount($$self)-1) {
        push @retval, $self->GetGeomFieldDefn($i);
    }
    return @retval;
}

sub AddFieldDefn {
    my ($self, $d) = @_;
    Geo::GDAL::FFI::OGR_FD_AddFieldDefn($$self, $$d);
}

sub AddGeomFieldDefn {
    my ($self, $d) = @_;
    Geo::GDAL::FFI::OGR_FD_AddGeomFieldDefn($$self, $$d);
}

sub DeleteFieldDefn {
    my ($self, $i) = @_;
    $i //= 0;
    $i = $self->GetFieldIndex($i) unless Geo::GDAL::FFI::isint($i);
    Geo::GDAL::FFI::OGR_FD_DeleteFieldDefn($$self, $i);
}

sub DeleteGeomFieldDefn {
    my ($self, $i) = @_;
    $i //= 0;
    $i = $self->GetGeomFieldIndex($i) unless Geo::GDAL::FFI::isint($i);
    Geo::GDAL::FFI::OGR_FD_DeleteGeomFieldDefn($$self, $i);
}

sub GetGeomType {
    my ($self) = @_;
    return $Geo::GDAL::FFI::geometry_types_reverse{Geo::GDAL::FFI::OGR_FD_GetGeomType($$self)};
}

sub SetGeomType {
    my ($self, $type) = @_;
    $type //= 'Unknown';
    my $tmp = $Geo::GDAL::FFI::geometry_types{$type};
    confess "Unknown geometry type: $type\n" unless defined $tmp;
    Geo::GDAL::FFI::OGR_FD_SetGeomType($$self, $tmp);
}

sub IsGeometryIgnored {
    my ($self) = @_;
    Geo::GDAL::FFI::OGR_FD_IsGeometryIgnored($$self);
}

sub SetGeometryIgnored {
    my ($self, $i) = @_;
    $i //= 1;
    Geo::GDAL::FFI::OGR_FD_SetGeometryIgnored($$self, $i);
}

sub IsStyleIgnored {
    my ($self) = @_;
    Geo::GDAL::FFI::OGR_FD_IsStyleIgnored($$self);
}

sub SetStyleIgnored {
    my ($self, $i) = @_;
    $i //= 1;
    Geo::GDAL::FFI::OGR_FD_SetStyleIgnored($$self, $i);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::FeatureDefn - A GDAL feature schema

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

 $defn = Geo::GDAL::FFI::FeatureDefn->new({Fields => [...], GeometryType => 'Point'});

Create a new FeatureDefn object.

The named arguments (optional) are the following.

=over 4

=item C<Name>

Optional; the name for this feature class; default is the empty
string.

=item C<Fields>

Optional, a reference to an array of FieldDefn objects or schemas.

=item C<GeometryFields>

Optional, a reference to an array of GeomFieldDefn objects or schemas.

=item C<GeometryType>

Optional, the type for the first geometry field; default is
Unknown. Note that this argument is ignored if GeometryFields is
given.

=item C<StyleIgnored>

=back

=head2 GetSchema

Returns the definition as a perl data structure.

=head2 GetFieldDefn

 my $field_defn = $defn->GetFieldDefn($name);

Get the specified non spatial field object. If the argument is
explicitly an integer and not a string, it is taken as the field
index.

=head2 GetFieldDefns

 my @field_defns = $defn->GetFieldDefns;

=head2 GetGeomFieldDefn

 my $geom_field_defn = $defn->GetGeomFieldDefn($name);

Get the specified spatial field object. If the argument is explicitly
an integer and not a string, it is taken as the field index.

=head2 GetGeomFieldDefns

 my @geom_field_defns = $defn->GetGeomFieldDefns;

=head2 SetGeometryIgnored

 $defn->SetGeometryIgnored($arg);

Ignore the first geometry field when reading features from a layer. To
not ignore the first geometry field call this method with defined but
false (0) argument.

=head2 IsGeometryIgnored

 my $is = $defn->IsGeometryIgnored;

Is the first geometry field ignored when reading features from a
layer.

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
