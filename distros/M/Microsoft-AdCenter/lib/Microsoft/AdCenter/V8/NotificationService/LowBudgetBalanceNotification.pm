package Microsoft::AdCenter::V8::NotificationService::LowBudgetBalanceNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V8::NotificationService::AccountNotification/;

=head1 NAME

Microsoft::AdCenter::V8::NotificationService::LowBudgetBalanceNotification - Represents "LowBudgetBalanceNotification" in Microsoft AdCenter Notification Service.

=head1 INHERITANCE

Microsoft::AdCenter::V8::NotificationService::AccountNotification

=cut

sub _type_name {
    return 'LowBudgetBalanceNotification';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/notifications/Entities';
}

our @_attributes = (qw/
    AccountName
    AffectedCampaigns
    CustomerId
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountName => 'string',
    AffectedCampaigns => 'ArrayOfLowBudgetBalanceCampaignInfo',
    CustomerId => 'long',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountName => 0,
    AffectedCampaigns => 0,
    CustomerId => 0,
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

Remark: Inherited methods are not listed.

=head2 new

Creates a new instance

=head2 AccountName

Gets/sets AccountName (string)

=head2 AffectedCampaigns

Gets/sets AffectedCampaigns (ArrayOfLowBudgetBalanceCampaignInfo)

=head2 CustomerId

Gets/sets CustomerId (long)

=cut

