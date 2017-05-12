package Microsoft::AdCenter::V8::NotificationService::Notification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::NotificationService::Notification - Represents "Notification" in Microsoft AdCenter Notification Service.

=cut

sub _type_name {
    return 'Notification';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/notifications/Entities';
}

our @_attributes = (qw/
    NotificationDate
    NotificationId
    NotificationType
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    NotificationDate => 'dateTime',
    NotificationId => 'long',
    NotificationType => 'NotificationType',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    NotificationDate => 0,
    NotificationId => 0,
    NotificationType => 0,
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

=head2 NotificationDate

Gets/sets NotificationDate (dateTime)

=head2 NotificationId

Gets/sets NotificationId (long)

=head2 NotificationType

Gets/sets NotificationType (NotificationType)

=cut

