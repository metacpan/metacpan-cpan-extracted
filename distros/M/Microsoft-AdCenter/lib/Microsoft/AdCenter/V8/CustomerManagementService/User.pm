package Microsoft::AdCenter::V8::CustomerManagementService::User;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::User - Represents "User" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'User';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    ContactInfo
    CustomerAppScope
    CustomerId
    Id
    JobTitle
    LastModifiedByUserId
    LastModifiedTime
    Lcid
    Name
    Password
    SecretAnswer
    SecretQuestion
    TimeStamp
    UserLifeCycleStatus
    UserName
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    ContactInfo => 'ContactInfo',
    CustomerAppScope => 'ApplicationType',
    CustomerId => 'long',
    Id => 'long',
    JobTitle => 'string',
    LastModifiedByUserId => 'long',
    LastModifiedTime => 'dateTime',
    Lcid => 'LCID',
    Name => 'PersonName',
    Password => 'string',
    SecretAnswer => 'string',
    SecretQuestion => 'SecretQuestion',
    TimeStamp => 'base64Binary',
    UserLifeCycleStatus => 'UserLifeCycleStatus',
    UserName => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    ContactInfo => 0,
    CustomerAppScope => 0,
    CustomerId => 0,
    Id => 0,
    JobTitle => 0,
    LastModifiedByUserId => 0,
    LastModifiedTime => 0,
    Lcid => 0,
    Name => 0,
    Password => 0,
    SecretAnswer => 0,
    SecretQuestion => 0,
    TimeStamp => 0,
    UserLifeCycleStatus => 0,
    UserName => 0,
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

=head2 ContactInfo

Gets/sets ContactInfo (ContactInfo)

=head2 CustomerAppScope

Gets/sets CustomerAppScope (ApplicationType)

=head2 CustomerId

Gets/sets CustomerId (long)

=head2 Id

Gets/sets Id (long)

=head2 JobTitle

Gets/sets JobTitle (string)

=head2 LastModifiedByUserId

Gets/sets LastModifiedByUserId (long)

=head2 LastModifiedTime

Gets/sets LastModifiedTime (dateTime)

=head2 Lcid

Gets/sets Lcid (LCID)

=head2 Name

Gets/sets Name (PersonName)

=head2 Password

Gets/sets Password (string)

=head2 SecretAnswer

Gets/sets SecretAnswer (string)

=head2 SecretQuestion

Gets/sets SecretQuestion (SecretQuestion)

=head2 TimeStamp

Gets/sets TimeStamp (base64Binary)

=head2 UserLifeCycleStatus

Gets/sets UserLifeCycleStatus (UserLifeCycleStatus)

=head2 UserName

Gets/sets UserName (string)

=cut

