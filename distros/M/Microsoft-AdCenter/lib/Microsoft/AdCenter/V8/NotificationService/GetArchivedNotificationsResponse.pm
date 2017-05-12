package Microsoft::AdCenter::V8::NotificationService::GetArchivedNotificationsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::NotificationService::GetArchivedNotificationsResponse - Represents "GetArchivedNotificationsResponse" in Microsoft AdCenter Notification Service.

=cut

sub _type_name {
    return 'GetArchivedNotificationsResponse';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/notifications/Entities';
}

our @_attributes = (qw/
    Notifications
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Notifications => 'ArrayOfNotification',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Notifications => 1,
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

=head2 Notifications

Gets/sets Notifications (ArrayOfNotification)

=cut

