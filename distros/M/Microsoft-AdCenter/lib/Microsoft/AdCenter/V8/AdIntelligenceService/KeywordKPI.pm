package Microsoft::AdCenter::V8::AdIntelligenceService::KeywordKPI;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::AdIntelligenceService::KeywordKPI - Represents "KeywordKPI" in Microsoft AdCenter Ad Intelligence Service.

=cut

sub _type_name {
    return 'KeywordKPI';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts';
}

our @_attributes = (qw/
    AdPosition
    AverageBid
    AverageCPC
    CTR
    Clicks
    Impressions
    MatchType
    TotalCost
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AdPosition => 'AdPosition',
    AverageBid => 'double',
    AverageCPC => 'double',
    CTR => 'double',
    Clicks => 'int',
    Impressions => 'int',
    MatchType => 'MatchType',
    TotalCost => 'double',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AdPosition => 0,
    AverageBid => 0,
    AverageCPC => 0,
    CTR => 0,
    Clicks => 0,
    Impressions => 0,
    MatchType => 0,
    TotalCost => 0,
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

=head2 AdPosition

Gets/sets AdPosition (AdPosition)

=head2 AverageBid

Gets/sets AverageBid (double)

=head2 AverageCPC

Gets/sets AverageCPC (double)

=head2 CTR

Gets/sets CTR (double)

=head2 Clicks

Gets/sets Clicks (int)

=head2 Impressions

Gets/sets Impressions (int)

=head2 MatchType

Gets/sets MatchType (MatchType)

=head2 TotalCost

Gets/sets TotalCost (double)

=cut

