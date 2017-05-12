package Microsoft::AdCenter::V8::CampaignManagementService::Campaign;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::Campaign - Represents "Campaign" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'Campaign';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    BudgetType
    ConversionTrackingEnabled
    DailyBudget
    DaylightSaving
    Description
    Id
    MonthlyBudget
    Name
    Status
    TimeZone
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    BudgetType => 'BudgetLimitType',
    ConversionTrackingEnabled => 'boolean',
    DailyBudget => 'double',
    DaylightSaving => 'boolean',
    Description => 'string',
    Id => 'long',
    MonthlyBudget => 'double',
    Name => 'string',
    Status => 'CampaignStatus',
    TimeZone => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    BudgetType => 0,
    ConversionTrackingEnabled => 0,
    DailyBudget => 0,
    DaylightSaving => 0,
    Description => 0,
    Id => 0,
    MonthlyBudget => 0,
    Name => 0,
    Status => 0,
    TimeZone => 0,
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

=head2 BudgetType

Gets/sets BudgetType (BudgetLimitType)

=head2 ConversionTrackingEnabled

Gets/sets ConversionTrackingEnabled (boolean)

=head2 DailyBudget

Gets/sets DailyBudget (double)

=head2 DaylightSaving

Gets/sets DaylightSaving (boolean)

=head2 Description

Gets/sets Description (string)

=head2 Id

Gets/sets Id (long)

=head2 MonthlyBudget

Gets/sets MonthlyBudget (double)

=head2 Name

Gets/sets Name (string)

=head2 Status

Gets/sets Status (CampaignStatus)

=head2 TimeZone

Gets/sets TimeZone (string)

=cut

