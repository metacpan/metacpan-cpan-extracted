package Microsoft::AdCenter::V6::CampaignManagementService::AdGroup;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::CampaignManagementService::AdGroup - Represents "AdGroup" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'AdGroup';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v6';
}

our @_attributes = (qw/
    AdDistribution
    BiddingModel
    BroadMatchBid
    CashBackInfo
    ContentMatchBid
    EndDate
    ExactMatchBid
    Id
    LanguageAndRegion
    Name
    NegativeKeywords
    NegativeSiteUrls
    PhraseMatchBid
    PricingModel
    StartDate
    Status
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AdDistribution => 'AdDistribution',
    BiddingModel => 'BiddingModel',
    BroadMatchBid => 'Bid',
    CashBackInfo => 'CashBackInfo',
    ContentMatchBid => 'Bid',
    EndDate => 'Date',
    ExactMatchBid => 'Bid',
    Id => 'long',
    LanguageAndRegion => 'string',
    Name => 'string',
    NegativeKeywords => 'ArrayOfstring',
    NegativeSiteUrls => 'ArrayOfstring',
    PhraseMatchBid => 'Bid',
    PricingModel => 'PricingModel',
    StartDate => 'Date',
    Status => 'AdGroupStatus',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AdDistribution => 0,
    BiddingModel => 0,
    BroadMatchBid => 0,
    CashBackInfo => 0,
    ContentMatchBid => 0,
    EndDate => 0,
    ExactMatchBid => 0,
    Id => 0,
    LanguageAndRegion => 0,
    Name => 0,
    NegativeKeywords => 0,
    NegativeSiteUrls => 0,
    PhraseMatchBid => 0,
    PricingModel => 0,
    StartDate => 0,
    Status => 0,
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

=head2 AdDistribution

Gets/sets AdDistribution (AdDistribution)

=head2 BiddingModel

Gets/sets BiddingModel (BiddingModel)

=head2 BroadMatchBid

Gets/sets BroadMatchBid (Bid)

=head2 CashBackInfo

Gets/sets CashBackInfo (CashBackInfo)

=head2 ContentMatchBid

Gets/sets ContentMatchBid (Bid)

=head2 EndDate

Gets/sets EndDate (Date)

=head2 ExactMatchBid

Gets/sets ExactMatchBid (Bid)

=head2 Id

Gets/sets Id (long)

=head2 LanguageAndRegion

Gets/sets LanguageAndRegion (string)

=head2 Name

Gets/sets Name (string)

=head2 NegativeKeywords

Gets/sets NegativeKeywords (ArrayOfstring)

=head2 NegativeSiteUrls

Gets/sets NegativeSiteUrls (ArrayOfstring)

=head2 PhraseMatchBid

Gets/sets PhraseMatchBid (Bid)

=head2 PricingModel

Gets/sets PricingModel (PricingModel)

=head2 StartDate

Gets/sets StartDate (Date)

=head2 Status

Gets/sets Status (AdGroupStatus)

=cut

