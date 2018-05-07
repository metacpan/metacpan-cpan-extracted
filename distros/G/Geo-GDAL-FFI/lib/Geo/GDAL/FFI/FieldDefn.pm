package Geo::GDAL::FFI::FieldDefn;
use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = 0.04;

sub new {
    my ($class, $args) = @_;
    my $name = $args->{Name} // 'Unnamed';
    my $type = $args->{Type} // 'String';
    my $tmp = $Geo::GDAL::FFI::field_types{$type};
    confess "Unknown field type: '$type'\n" unless defined $tmp;
    my $self = bless \Geo::GDAL::FFI::OGR_Fld_Create($name, $tmp), $class;
    $self->SetDefault($args->{Default}) if defined $args->{Default};
    $self->SetSubtype($args->{Subtype}) if defined $args->{Subtype};
    $self->SetJustify($args->{Justify}) if defined $args->{Justify};
    $self->SetWidth($args->{Width}) if defined $args->{Width};
    $self->SetPrecision($args->{Precision}) if defined $args->{Precision};
    $self->SetNullable(0) if $args->{NotNullable};
    return $self;
}

sub DESTROY {
    my $self = shift;
    #say STDERR "destroy $self => $$self";
    if ($Geo::GDAL::FFI::immutable{$$self}) {
        #say STDERR "remove it from immutable";
        $Geo::GDAL::FFI::immutable{$$self}--;
        delete $Geo::GDAL::FFI::immutable{$$self} if $Geo::GDAL::FFI::immutable{$$self} == 0;
    } else {
        #say STDERR "destroy it";
        Geo::GDAL::FFI::OGR_Fld_Destroy($$self);
    }
}

sub GetSchema {
    my $self = shift;
    my $schema = {
        Name => $self->GetName,
        Type => $self->GetType,
        Subtype => $self->GetSubtype,
        Justify => $self->GetJustify,
        Width => $self->GetWidth,
        Precision => $self->GetPrecision,
    };
    my $default = $self->GetDefault;
    $schema->{Default} = $default if defined $default;
    $schema->{NotNullable} = 1 unless $self->IsNullable;
    return $schema;
}

sub SetName {
    my ($self, $name) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $name //= '';
    Geo::GDAL::FFI::OGR_Fld_SetName($$self, $name);
}

sub GetName {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_Fld_GetNameRef($$self);
}

sub SetType {
    my ($self, $type) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $type //= 'String';
    my $tmp = $Geo::GDAL::FFI::field_types{$type};
    confess "Unknown field type: $type\n" unless defined $tmp;
    $type = $tmp;
    Geo::GDAL::FFI::OGR_Fld_SetType($$self, $type);
}

sub GetType {
    my ($self) = @_;
    return $Geo::GDAL::FFI::field_types_reverse{Geo::GDAL::FFI::OGR_Fld_GetType($$self)};
}

sub GetDefault {
    my $self = shift;
    return Geo::GDAL::FFI::OGR_Fld_GetDefault($$self)
}

sub SetDefault {
    my ($self, $default) = @_;
    Geo::GDAL::FFI::OGR_Fld_SetDefault($$self, $default);
}

sub IsDefaultDriverSpecific {
    my $self = shift;
    return Geo::GDAL::FFI::OGR_Fld_IsDefaultDriverSpecific($$self);
}

sub SetSubtype {
    my ($self, $subtype) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $subtype //= 'None';
    my $tmp = $Geo::GDAL::FFI::field_subtypes{$subtype};
    confess "Unknown field subtype: $subtype\n" unless defined $tmp;
    $subtype = $tmp;
    Geo::GDAL::FFI::OGR_Fld_SetSubType($$self, $subtype);
}

sub GetSubtype {
    my ($self) = @_;
    return $Geo::GDAL::FFI::field_subtypes_reverse{Geo::GDAL::FFI::OGR_Fld_GetSubType($$self)};
}

sub SetJustify {
    my ($self, $justify) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $justify //= 'Undefined';
    my $tmp = $Geo::GDAL::FFI::justification{$justify};
    confess "Unknown constant: $justify\n" unless defined $tmp;
    $justify = $tmp;
    Geo::GDAL::FFI::OGR_Fld_SetJustify($$self, $justify);
}

sub GetJustify {
    my ($self) = @_;
    return $Geo::GDAL::FFI::justification_reverse{Geo::GDAL::FFI::OGR_Fld_GetJustify($$self)};
}

sub SetWidth {
    my ($self, $width) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $width //= '';
    Geo::GDAL::FFI::OGR_Fld_SetWidth($$self, $width);
}

sub GetWidth {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_Fld_GetWidth($$self);
}

sub SetPrecision {
    my ($self, $precision) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $precision //= '';
    Geo::GDAL::FFI::OGR_Fld_SetPrecision($$self, $precision);
}

sub GetPrecision {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_Fld_GetPrecision($$self);
}

sub SetIgnored {
    my ($self, $ignored) = @_;
    #confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $ignored //= 1;
    Geo::GDAL::FFI::OGR_Fld_SetIgnored($$self, $ignored);
}

sub IsIgnored {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_Fld_IsIgnored($$self);
}

sub SetNullable {
    my ($self, $nullable) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    $nullable //= 0;
    Geo::GDAL::FFI::OGR_Fld_SetNullable($$self, $nullable);
}

sub IsNullable {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_Fld_IsNullable($$self);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::FieldDefn - A field in a GDAL feature schema

=head1 SYNOPSIS

=head1 DESCRIPTION

There should not usually be any reason to directly access this method
except for the ignore methods. This object is created/read from/to the
Perl data structure in the CreateLayer method of a dataset, or in the
constructor or schema method of FeatureDefn.

The schema of a FieldDefn is (Name, Type, Default, Subtype, Justify,
Width, Precision, NotNullable).

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
