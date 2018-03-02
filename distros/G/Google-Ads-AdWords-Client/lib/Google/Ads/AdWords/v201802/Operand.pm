package Google::Ads::AdWords::v201802::Operand;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201802' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

{ # BLOCK to scope variables

my %AdGroupAdLabel_of :ATTR(:get<AdGroupAdLabel>);
my %AdGroupAd_of :ATTR(:get<AdGroupAd>);
my %AdGroupBidModifier_of :ATTR(:get<AdGroupBidModifier>);
my %AdGroupCriterionLabel_of :ATTR(:get<AdGroupCriterionLabel>);
my %AdGroupCriterion_of :ATTR(:get<AdGroupCriterion>);
my %AdGroupExtensionSetting_of :ATTR(:get<AdGroupExtensionSetting>);
my %AdGroupLabel_of :ATTR(:get<AdGroupLabel>);
my %AdGroup_of :ATTR(:get<AdGroup>);
my %Ad_of :ATTR(:get<Ad>);
my %Budget_of :ATTR(:get<Budget>);
my %CampaignCriterion_of :ATTR(:get<CampaignCriterion>);
my %CampaignExtensionSetting_of :ATTR(:get<CampaignExtensionSetting>);
my %CampaignLabel_of :ATTR(:get<CampaignLabel>);
my %CampaignSharedSet_of :ATTR(:get<CampaignSharedSet>);
my %Campaign_of :ATTR(:get<Campaign>);
my %CustomerExtensionSetting_of :ATTR(:get<CustomerExtensionSetting>);
my %ExtensionFeedItem_of :ATTR(:get<ExtensionFeedItem>);
my %FeedItemTarget_of :ATTR(:get<FeedItemTarget>);
my %FeedItem_of :ATTR(:get<FeedItem>);
my %Label_of :ATTR(:get<Label>);
my %Media_of :ATTR(:get<Media>);
my %SharedCriterion_of :ATTR(:get<SharedCriterion>);
my %SharedSet_of :ATTR(:get<SharedSet>);

__PACKAGE__->_factory(
    [ qw(        AdGroupAdLabel
        AdGroupAd
        AdGroupBidModifier
        AdGroupCriterionLabel
        AdGroupCriterion
        AdGroupExtensionSetting
        AdGroupLabel
        AdGroup
        Ad
        Budget
        CampaignCriterion
        CampaignExtensionSetting
        CampaignLabel
        CampaignSharedSet
        Campaign
        CustomerExtensionSetting
        ExtensionFeedItem
        FeedItemTarget
        FeedItem
        Label
        Media
        SharedCriterion
        SharedSet

    ) ],
    {
        'AdGroupAdLabel' => \%AdGroupAdLabel_of,
        'AdGroupAd' => \%AdGroupAd_of,
        'AdGroupBidModifier' => \%AdGroupBidModifier_of,
        'AdGroupCriterionLabel' => \%AdGroupCriterionLabel_of,
        'AdGroupCriterion' => \%AdGroupCriterion_of,
        'AdGroupExtensionSetting' => \%AdGroupExtensionSetting_of,
        'AdGroupLabel' => \%AdGroupLabel_of,
        'AdGroup' => \%AdGroup_of,
        'Ad' => \%Ad_of,
        'Budget' => \%Budget_of,
        'CampaignCriterion' => \%CampaignCriterion_of,
        'CampaignExtensionSetting' => \%CampaignExtensionSetting_of,
        'CampaignLabel' => \%CampaignLabel_of,
        'CampaignSharedSet' => \%CampaignSharedSet_of,
        'Campaign' => \%Campaign_of,
        'CustomerExtensionSetting' => \%CustomerExtensionSetting_of,
        'ExtensionFeedItem' => \%ExtensionFeedItem_of,
        'FeedItemTarget' => \%FeedItemTarget_of,
        'FeedItem' => \%FeedItem_of,
        'Label' => \%Label_of,
        'Media' => \%Media_of,
        'SharedCriterion' => \%SharedCriterion_of,
        'SharedSet' => \%SharedSet_of,
    },
    {
        'AdGroupAdLabel' => 'Google::Ads::AdWords::v201802::AdGroupAdLabel',
        'AdGroupAd' => 'Google::Ads::AdWords::v201802::AdGroupAd',
        'AdGroupBidModifier' => 'Google::Ads::AdWords::v201802::AdGroupBidModifier',
        'AdGroupCriterionLabel' => 'Google::Ads::AdWords::v201802::AdGroupCriterionLabel',
        'AdGroupCriterion' => 'Google::Ads::AdWords::v201802::AdGroupCriterion',
        'AdGroupExtensionSetting' => 'Google::Ads::AdWords::v201802::AdGroupExtensionSetting',
        'AdGroupLabel' => 'Google::Ads::AdWords::v201802::AdGroupLabel',
        'AdGroup' => 'Google::Ads::AdWords::v201802::AdGroup',
        'Ad' => 'Google::Ads::AdWords::v201802::Ad',
        'Budget' => 'Google::Ads::AdWords::v201802::Budget',
        'CampaignCriterion' => 'Google::Ads::AdWords::v201802::CampaignCriterion',
        'CampaignExtensionSetting' => 'Google::Ads::AdWords::v201802::CampaignExtensionSetting',
        'CampaignLabel' => 'Google::Ads::AdWords::v201802::CampaignLabel',
        'CampaignSharedSet' => 'Google::Ads::AdWords::v201802::CampaignSharedSet',
        'Campaign' => 'Google::Ads::AdWords::v201802::Campaign',
        'CustomerExtensionSetting' => 'Google::Ads::AdWords::v201802::CustomerExtensionSetting',
        'ExtensionFeedItem' => 'Google::Ads::AdWords::v201802::ExtensionFeedItem',
        'FeedItemTarget' => 'Google::Ads::AdWords::v201802::FeedItemTarget',
        'FeedItem' => 'Google::Ads::AdWords::v201802::FeedItem',
        'Label' => 'Google::Ads::AdWords::v201802::Label',
        'Media' => 'Google::Ads::AdWords::v201802::Media',
        'SharedCriterion' => 'Google::Ads::AdWords::v201802::SharedCriterion',
        'SharedSet' => 'Google::Ads::AdWords::v201802::SharedSet',
    },
    {

        'AdGroupAdLabel' => 'AdGroupAdLabel',
        'AdGroupAd' => 'AdGroupAd',
        'AdGroupBidModifier' => 'AdGroupBidModifier',
        'AdGroupCriterionLabel' => 'AdGroupCriterionLabel',
        'AdGroupCriterion' => 'AdGroupCriterion',
        'AdGroupExtensionSetting' => 'AdGroupExtensionSetting',
        'AdGroupLabel' => 'AdGroupLabel',
        'AdGroup' => 'AdGroup',
        'Ad' => 'Ad',
        'Budget' => 'Budget',
        'CampaignCriterion' => 'CampaignCriterion',
        'CampaignExtensionSetting' => 'CampaignExtensionSetting',
        'CampaignLabel' => 'CampaignLabel',
        'CampaignSharedSet' => 'CampaignSharedSet',
        'Campaign' => 'Campaign',
        'CustomerExtensionSetting' => 'CustomerExtensionSetting',
        'ExtensionFeedItem' => 'ExtensionFeedItem',
        'FeedItemTarget' => 'FeedItemTarget',
        'FeedItem' => 'FeedItem',
        'Label' => 'Label',
        'Media' => 'Media',
        'SharedCriterion' => 'SharedCriterion',
        'SharedSet' => 'SharedSet',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201802::Operand

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Operand from the namespace https://adwords.google.com/api/adwords/cm/v201802.

A marker interface for entities that can be operated upon in mutate operations. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * AdGroupAdLabel


=item * AdGroupAd


=item * AdGroupBidModifier


=item * AdGroupCriterionLabel


=item * AdGroupCriterion


=item * AdGroupExtensionSetting


=item * AdGroupLabel


=item * AdGroup


=item * Ad


=item * Budget


=item * CampaignCriterion


=item * CampaignExtensionSetting


=item * CampaignLabel


=item * CampaignSharedSet


=item * Campaign


=item * CustomerExtensionSetting


=item * ExtensionFeedItem


=item * FeedItemTarget


=item * FeedItem


=item * Label


=item * Media


=item * SharedCriterion


=item * SharedSet




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

