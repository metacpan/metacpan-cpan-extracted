package Microsoft::AdCenter::V8::NotificationService::CampaignInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::NotificationService::CampaignInfo - Represents "CampaignInfo" in Microsoft AdCenter Notification Service.

=cut

sub _type_name {
    return 'CampaignInfo';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/notifications/Entities';
}

our @_attributes = (qw/
    BudgetAmount
    CampaignId
    CampaignName
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    BudgetAmount => 'double',
    CampaignId => 'long',
    CampaignName => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    BudgetAmount => 0,
    CampaignId => 0,
    CampaignName => 0,
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

=head2 BudgetAmount

Gets/sets BudgetAmount (double)

=head2 CampaignId

Gets/sets CampaignId (long)

=head2 CampaignName

Gets/sets CampaignName (string)

=cut

