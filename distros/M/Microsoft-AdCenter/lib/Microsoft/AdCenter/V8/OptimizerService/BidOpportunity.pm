package Microsoft::AdCenter::V8::OptimizerService::BidOpportunity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V8::OptimizerService::Opportunity/;

=head1 NAME

Microsoft::AdCenter::V8::OptimizerService::BidOpportunity - Represents "BidOpportunity" in Microsoft AdCenter Optimizer Service.

=head1 INHERITANCE

Microsoft::AdCenter::V8::OptimizerService::Opportunity

=cut

sub _type_name {
    return 'BidOpportunity';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.Optimizer.Api.DataContracts.Entities';
}

our @_attributes = (qw/
    AdGroupId
    CurrentBid
    EstimatedIncreaseInClicks
    EstimatedIncreaseInCost
    EstimatedIncreaseInImpressions
    KeywordId
    MatchType
    SuggestedBid
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AdGroupId => 'long',
    CurrentBid => 'double',
    EstimatedIncreaseInClicks => 'int',
    EstimatedIncreaseInCost => 'double',
    EstimatedIncreaseInImpressions => 'int',
    KeywordId => 'long',
    MatchType => 'string',
    SuggestedBid => 'double',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AdGroupId => 0,
    CurrentBid => 0,
    EstimatedIncreaseInClicks => 0,
    EstimatedIncreaseInCost => 0,
    EstimatedIncreaseInImpressions => 0,
    KeywordId => 0,
    MatchType => 0,
    SuggestedBid => 0,
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

=head2 AdGroupId

Gets/sets AdGroupId (long)

=head2 CurrentBid

Gets/sets CurrentBid (double)

=head2 EstimatedIncreaseInClicks

Gets/sets EstimatedIncreaseInClicks (int)

=head2 EstimatedIncreaseInCost

Gets/sets EstimatedIncreaseInCost (double)

=head2 EstimatedIncreaseInImpressions

Gets/sets EstimatedIncreaseInImpressions (int)

=head2 KeywordId

Gets/sets KeywordId (long)

=head2 MatchType

Gets/sets MatchType (string)

=head2 SuggestedBid

Gets/sets SuggestedBid (double)

=cut

