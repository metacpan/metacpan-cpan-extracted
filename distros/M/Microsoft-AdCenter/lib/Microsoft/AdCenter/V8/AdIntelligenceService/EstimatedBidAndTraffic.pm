package Microsoft::AdCenter::V8::AdIntelligenceService::EstimatedBidAndTraffic;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::AdIntelligenceService::EstimatedBidAndTraffic - Represents "EstimatedBidAndTraffic" in Microsoft AdCenter Ad Intelligence Service.

=cut

sub _type_name {
    return 'EstimatedBidAndTraffic';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts';
}

our @_attributes = (qw/
    AverageCPC
    CTR
    Currency
    EstimatedMinBid
    MatchType
    MaxClicksPerWeek
    MaxImpressionsPerWeek
    MaxTotalCostPerWeek
    MinClicksPerWeek
    MinImpressionsPerWeek
    MinTotalCostPerWeek
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AverageCPC => 'double',
    CTR => 'double',
    Currency => 'Currency',
    EstimatedMinBid => 'double',
    MatchType => 'MatchType',
    MaxClicksPerWeek => 'int',
    MaxImpressionsPerWeek => 'int',
    MaxTotalCostPerWeek => 'double',
    MinClicksPerWeek => 'int',
    MinImpressionsPerWeek => 'int',
    MinTotalCostPerWeek => 'double',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AverageCPC => 0,
    CTR => 0,
    Currency => 0,
    EstimatedMinBid => 0,
    MatchType => 0,
    MaxClicksPerWeek => 0,
    MaxImpressionsPerWeek => 0,
    MaxTotalCostPerWeek => 0,
    MinClicksPerWeek => 0,
    MinImpressionsPerWeek => 0,
    MinTotalCostPerWeek => 0,
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

=head2 AverageCPC

Gets/sets AverageCPC (double)

=head2 CTR

Gets/sets CTR (double)

=head2 Currency

Gets/sets Currency (Currency)

=head2 EstimatedMinBid

Gets/sets EstimatedMinBid (double)

=head2 MatchType

Gets/sets MatchType (MatchType)

=head2 MaxClicksPerWeek

Gets/sets MaxClicksPerWeek (int)

=head2 MaxImpressionsPerWeek

Gets/sets MaxImpressionsPerWeek (int)

=head2 MaxTotalCostPerWeek

Gets/sets MaxTotalCostPerWeek (double)

=head2 MinClicksPerWeek

Gets/sets MinClicksPerWeek (int)

=head2 MinImpressionsPerWeek

Gets/sets MinImpressionsPerWeek (int)

=head2 MinTotalCostPerWeek

Gets/sets MinTotalCostPerWeek (double)

=cut

