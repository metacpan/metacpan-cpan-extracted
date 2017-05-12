package Microsoft::AdCenter::V6::CustomerManagementService::AdCenterContactInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterContactInfo - Represents "AdCenterContactInfo" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'AdCenterContactInfo';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    Fax
    HomePhone
    Mobile
    Phone1
    Phone2
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Fax => 'string',
    HomePhone => 'string',
    Mobile => 'string',
    Phone1 => 'string',
    Phone2 => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Fax => 0,
    HomePhone => 0,
    Mobile => 0,
    Phone1 => 0,
    Phone2 => 0,
);

sub _attribute_min_occurs {
    my ($self, $attribute) = @_;
    if (exists $_attribute_min_occurs{$attribute}) {
        return $_attribute_min_occurs{$attribute};
    }
    return $self->SUPER::_attribute_min_occurs($attribute);
}

__PACKAGE__->mk_accessors(@_attributes);

1;

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=cut

=head1 METHODS

=head2 new

Creates a new instance

=head2 Fax

Gets/sets Fax (string)

=head2 HomePhone

Gets/sets HomePhone (string)

=head2 Mobile

Gets/sets Mobile (string)

=head2 Phone1

Gets/sets Phone1 (string)

=head2 Phone2

Gets/sets Phone2 (string)

=cut

