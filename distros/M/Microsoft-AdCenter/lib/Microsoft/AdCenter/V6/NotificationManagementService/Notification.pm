package Microsoft::AdCenter::V6::NotificationManagementService::Notification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::NotificationManagementService::Notification - Represents "Notification" in Microsoft AdCenter Notification Management Service.

=cut

sub _type_name {
    return 'Notification';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    CustomerId
    NotificationDate
    NotificationType
    RecipientEmailAddress
    UserLocale
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    CustomerId => 'int',
    NotificationDate => 'dateTime',
    NotificationType => 'NotificationType',
    RecipientEmailAddress => 'string',
    UserLocale => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    CustomerId => 1,
    NotificationDate => 1,
    NotificationType => 1,
    RecipientEmailAddress => 0,
    UserLocale => 0,
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

=head2 CustomerId

Gets/sets CustomerId (int)

=head2 NotificationDate

Gets/sets NotificationDate (dateTime)

=head2 NotificationType

Gets/sets NotificationType (NotificationType)

=head2 RecipientEmailAddress

Gets/sets RecipientEmailAddress (string)

=head2 UserLocale

Gets/sets UserLocale (string)

=cut

