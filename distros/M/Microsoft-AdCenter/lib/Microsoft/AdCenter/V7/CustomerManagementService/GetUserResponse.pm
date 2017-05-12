package Microsoft::AdCenter::V7::CustomerManagementService::GetUserResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::GetUserResponse - Represents "GetUserResponse" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'GetUserResponse';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement';
}

our @_attributes = (qw/
    Accounts
    Customers
    Roles
    User
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Accounts => 'ArrayOflong',
    Customers => 'ArrayOflong',
    Roles => 'ArrayOfint',
    User => 'User',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Accounts => 1,
    Customers => 1,
    Roles => 1,
    User => 1,
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

=head2 Accounts

Gets/sets Accounts (ArrayOflong)

=head2 Customers

Gets/sets Customers (ArrayOflong)

=head2 Roles

Gets/sets Roles (ArrayOfint)

=head2 User

Gets/sets User (User)

=cut

