package Microsoft::AdCenter::V8::CampaignManagementService::AdGroup;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::AdGroup - Represents "AdGroup" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'AdGroup';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    AdDistribution
    BiddingModel
    BroadMatchBid
    ContentMatchBid
    EndDate
    ExactMatchBid
    Id
    Language
    Name
    Network
    PhraseMatchBid
    PricingModel
    PublisherCountries
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
    ContentMatchBid => 'Bid',
    EndDate => 'Date',
    ExactMatchBid => 'Bid',
    Id => 'long',
    Language => 'string',
    Name => 'string',
    Network => 'Network',
    PhraseMatchBid => 'Bid',
    PricingModel => 'PricingModel',
    PublisherCountries => 'ArrayOfPublisherCountry',
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
    ContentMatchBid => 0,
    EndDate => 0,
    ExactMatchBid => 0,
    Id => 0,
    Language => 0,
    Name => 0,
    Network => 0,
    PhraseMatchBid => 0,
    PricingModel => 0,
    PublisherCountries => 0,
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

=head2 ContentMatchBid

Gets/sets ContentMatchBid (Bid)

=head2 EndDate

Gets/sets EndDate (Date)

=head2 ExactMatchBid

Gets/sets ExactMatchBid (Bid)

=head2 Id

Gets/sets Id (long)

=head2 Language

Gets/sets Language (string)

=head2 Name

Gets/sets Name (string)

=head2 Network

Gets/sets Network (Network)

=head2 PhraseMatchBid

Gets/sets PhraseMatchBid (Bid)

=head2 PricingModel

Gets/sets PricingModel (PricingModel)

=head2 PublisherCountries

Gets/sets PublisherCountries (ArrayOfPublisherCountry)

=head2 StartDate

Gets/sets StartDate (Date)

=head2 Status

Gets/sets Status (AdGroupStatus)

=cut

