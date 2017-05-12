package Microsoft::AdCenter::ComplexType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Class::Accessor::Chained Microsoft::AdCenter/;

use Carp;
use DateTime::Format::W3CDTF;
use DateTime::Format::ISO8601;
use Scalar::Util qw/blessed/;

=head1 NAME

Microsoft::AdCenter::ComplexType - The base class for complex types.

=cut

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-US/library/ee730327%28v=MSADS.60%29.aspx> for documentation of the various data objects.

This module is not intended to be used directly.  Documentation for each of the complex types is in the appropriate module.

=head1 METHODS

=head2 attributes

Returns the name of all attributes

=head2 attribute_type

Returns the expected type of the supplied attribute name

=cut

sub new {
    my ($pkg, %args) = @_;
    my $self = bless {}, $pkg;
    my %attr = map { $_ => 1 } $self->_attributes;
    foreach my $key (keys %args) {
        if ($attr{$key}) {
            $self->$key($args{$key});
        }
    }
    return $self;
}

sub _type {
    my $self = shift;
    return (split /::/, ref $self)[-1] ;
}

sub attributes {
    return shift->_attributes;
}

sub _attributes {
    return ();
}

sub attribute_type {
    my $self = shift;
    return $self->_attribute_type(@_);
}

sub _attribute_type {
    my ($self, $attribute) = @_;
    die "Invalid attribute '$attribute'";
}

sub attribute_min_occurs {
    my $self = shift;
    return $self->_attribute_min_occurs(@_);
}

sub _attribute_min_occurs {
    my ($self, $attribute) = @_;
    die "Invalid attribute '$attribute'";
}

sub _force_datetime_object {
    my ($self, $value) = @_;
    if (defined $value) {
        unless (ref $value) { # Not a DateTime object
            $value = DateTime::Format::ISO8601->new->parse_datetime($value);
        }
        # Let's hope it looks like a DateTime object
        $value->set_formatter(DateTime::Format::W3CDTF->new);
    }
    return $value;
}

sub set {
    my ($self, $key, @values) = @_;
    my $type = $self->_attribute_type($key);
    if ($type eq "dateTime") {
        @values = map { $self->_force_datetime_object($_) } @values;
    }
    $self->SUPER::set($key, @values);
}

1;
