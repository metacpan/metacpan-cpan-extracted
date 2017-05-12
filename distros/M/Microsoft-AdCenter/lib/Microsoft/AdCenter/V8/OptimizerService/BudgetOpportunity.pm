package Microsoft::AdCenter::V8::OptimizerService::BudgetOpportunity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V8::OptimizerService::Opportunity/;

=head1 NAME

Microsoft::AdCenter::V8::OptimizerService::BudgetOpportunity - Represents "BudgetOpportunity" in Microsoft AdCenter Optimizer Service.

=head1 INHERITANCE

Microsoft::AdCenter::V8::OptimizerService::Opportunity

=cut

sub _type_name {
    return 'BudgetOpportunity';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.Optimizer.Api.DataContracts.Entities';
}

our @_attributes = (qw/
    BudgetDepletionDate
    BudgetType
    CampaignId
    CurrentBudget
    IncreaseInClicks
    IncreaseInImpressions
    PercentageIncreaseInClicks
    PercentageIncreaseInImpressions
    RecommendedBudget
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    BudgetDepletionDate => 'dateTime',
    BudgetType => 'BudgetLimitType',
    CampaignId => 'long',
    CurrentBudget => 'double',
    IncreaseInClicks => 'int',
    IncreaseInImpressions => 'int',
    PercentageIncreaseInClicks => 'int',
    PercentageIncreaseInImpressions => 'int',
    RecommendedBudget => 'double',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    BudgetDepletionDate => 0,
    BudgetType => 0,
    CampaignId => 0,
    CurrentBudget => 0,
    IncreaseInClicks => 0,
    IncreaseInImpressions => 0,
    PercentageIncreaseInClicks => 0,
    PercentageIncreaseInImpressions => 0,
    RecommendedBudget => 0,
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

=head2 BudgetDepletionDate

Gets/sets BudgetDepletionDate (dateTime)

=head2 BudgetType

Gets/sets BudgetType (BudgetLimitType)

=head2 CampaignId

Gets/sets CampaignId (long)

=head2 CurrentBudget

Gets/sets CurrentBudget (double)

=head2 IncreaseInClicks

Gets/sets IncreaseInClicks (int)

=head2 IncreaseInImpressions

Gets/sets IncreaseInImpressions (int)

=head2 PercentageIncreaseInClicks

Gets/sets PercentageIncreaseInClicks (int)

=head2 PercentageIncreaseInImpressions

Gets/sets PercentageIncreaseInImpressions (int)

=head2 RecommendedBudget

Gets/sets RecommendedBudget (double)

=cut

