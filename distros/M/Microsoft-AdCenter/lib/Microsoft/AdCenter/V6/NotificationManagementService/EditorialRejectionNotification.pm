package Microsoft::AdCenter::V6::NotificationManagementService::EditorialRejectionNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V6::NotificationManagementService::Notification/;

=head1 NAME

Microsoft::AdCenter::V6::NotificationManagementService::EditorialRejectionNotification - Represents "EditorialRejectionNotification" in Microsoft AdCenter Notification Management Service.

=head1 INHERITANCE

Microsoft::AdCenter::V6::NotificationManagementService::Notification

=cut

sub _type_name {
    return 'EditorialRejectionNotification';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    AccountId
    AccountName
    AccountNumber
    AdDescription
    AdId
    AdTitle
    CampaignId
    CampaignName
    CustomerName
    DestinationURL
    DisplayURL
    KeywordsAccepted
    KeywordsPending
    KeywordsRejected
    OrderId
    OrderName
    Top1Keyword
    Top1KeywordReason
    Top2Keyword
    Top2KeywordReason
    Top3Keyword
    Top3KeywordReason
    Top4Keyword
    Top4KeywordReason
    Top5Keyword
    Top5KeywordReason
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountId => 'int',
    AccountName => 'string',
    AccountNumber => 'string',
    AdDescription => 'string',
    AdId => 'int',
    AdTitle => 'string',
    CampaignId => 'int',
    CampaignName => 'string',
    CustomerName => 'string',
    DestinationURL => 'string',
    DisplayURL => 'string',
    KeywordsAccepted => 'int',
    KeywordsPending => 'int',
    KeywordsRejected => 'int',
    OrderId => 'int',
    OrderName => 'string',
    Top1Keyword => 'string',
    Top1KeywordReason => 'string',
    Top2Keyword => 'string',
    Top2KeywordReason => 'string',
    Top3Keyword => 'string',
    Top3KeywordReason => 'string',
    Top4Keyword => 'string',
    Top4KeywordReason => 'string',
    Top5Keyword => 'string',
    Top5KeywordReason => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountId => 1,
    AccountName => 0,
    AccountNumber => 0,
    AdDescription => 0,
    AdId => 1,
    AdTitle => 0,
    CampaignId => 1,
    CampaignName => 0,
    CustomerName => 0,
    DestinationURL => 0,
    DisplayURL => 0,
    KeywordsAccepted => 1,
    KeywordsPending => 1,
    KeywordsRejected => 1,
    OrderId => 1,
    OrderName => 0,
    Top1Keyword => 0,
    Top1KeywordReason => 0,
    Top2Keyword => 0,
    Top2KeywordReason => 0,
    Top3Keyword => 0,
    Top3KeywordReason => 0,
    Top4Keyword => 0,
    Top4KeywordReason => 0,
    Top5Keyword => 0,
    Top5KeywordReason => 0,
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

=head2 AccountId

Gets/sets AccountId (int)

=head2 AccountName

Gets/sets AccountName (string)

=head2 AccountNumber

Gets/sets AccountNumber (string)

=head2 AdDescription

Gets/sets AdDescription (string)

=head2 AdId

Gets/sets AdId (int)

=head2 AdTitle

Gets/sets AdTitle (string)

=head2 CampaignId

Gets/sets CampaignId (int)

=head2 CampaignName

Gets/sets CampaignName (string)

=head2 CustomerName

Gets/sets CustomerName (string)

=head2 DestinationURL

Gets/sets DestinationURL (string)

=head2 DisplayURL

Gets/sets DisplayURL (string)

=head2 KeywordsAccepted

Gets/sets KeywordsAccepted (int)

=head2 KeywordsPending

Gets/sets KeywordsPending (int)

=head2 KeywordsRejected

Gets/sets KeywordsRejected (int)

=head2 OrderId

Gets/sets OrderId (int)

=head2 OrderName

Gets/sets OrderName (string)

=head2 Top1Keyword

Gets/sets Top1Keyword (string)

=head2 Top1KeywordReason

Gets/sets Top1KeywordReason (string)

=head2 Top2Keyword

Gets/sets Top2Keyword (string)

=head2 Top2KeywordReason

Gets/sets Top2KeywordReason (string)

=head2 Top3Keyword

Gets/sets Top3Keyword (string)

=head2 Top3KeywordReason

Gets/sets Top3KeywordReason (string)

=head2 Top4Keyword

Gets/sets Top4Keyword (string)

=head2 Top4KeywordReason

Gets/sets Top4KeywordReason (string)

=head2 Top5Keyword

Gets/sets Top5Keyword (string)

=head2 Top5KeywordReason

Gets/sets Top5KeywordReason (string)

=cut

