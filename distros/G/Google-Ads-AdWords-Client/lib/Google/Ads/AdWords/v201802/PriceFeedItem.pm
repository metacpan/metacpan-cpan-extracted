package Google::Ads::AdWords::v201802::PriceFeedItem;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201802' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201802::ExtensionFeedItem);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

{ # BLOCK to scope variables

my %feedId_of :ATTR(:get<feedId>);
my %feedItemId_of :ATTR(:get<feedItemId>);
my %status_of :ATTR(:get<status>);
my %feedType_of :ATTR(:get<feedType>);
my %startTime_of :ATTR(:get<startTime>);
my %endTime_of :ATTR(:get<endTime>);
my %devicePreference_of :ATTR(:get<devicePreference>);
my %scheduling_of :ATTR(:get<scheduling>);
my %campaignTargeting_of :ATTR(:get<campaignTargeting>);
my %adGroupTargeting_of :ATTR(:get<adGroupTargeting>);
my %keywordTargeting_of :ATTR(:get<keywordTargeting>);
my %geoTargeting_of :ATTR(:get<geoTargeting>);
my %geoTargetingRestriction_of :ATTR(:get<geoTargetingRestriction>);
my %policyData_of :ATTR(:get<policyData>);
my %ExtensionFeedItem__Type_of :ATTR(:get<ExtensionFeedItem__Type>);
my %priceExtensionType_of :ATTR(:get<priceExtensionType>);
my %priceQualifier_of :ATTR(:get<priceQualifier>);
my %trackingUrlTemplate_of :ATTR(:get<trackingUrlTemplate>);
my %language_of :ATTR(:get<language>);
my %tableRows_of :ATTR(:get<tableRows>);

__PACKAGE__->_factory(
    [ qw(        feedId
        feedItemId
        status
        feedType
        startTime
        endTime
        devicePreference
        scheduling
        campaignTargeting
        adGroupTargeting
        keywordTargeting
        geoTargeting
        geoTargetingRestriction
        policyData
        ExtensionFeedItem__Type
        priceExtensionType
        priceQualifier
        trackingUrlTemplate
        language
        tableRows

    ) ],
    {
        'feedId' => \%feedId_of,
        'feedItemId' => \%feedItemId_of,
        'status' => \%status_of,
        'feedType' => \%feedType_of,
        'startTime' => \%startTime_of,
        'endTime' => \%endTime_of,
        'devicePreference' => \%devicePreference_of,
        'scheduling' => \%scheduling_of,
        'campaignTargeting' => \%campaignTargeting_of,
        'adGroupTargeting' => \%adGroupTargeting_of,
        'keywordTargeting' => \%keywordTargeting_of,
        'geoTargeting' => \%geoTargeting_of,
        'geoTargetingRestriction' => \%geoTargetingRestriction_of,
        'policyData' => \%policyData_of,
        'ExtensionFeedItem__Type' => \%ExtensionFeedItem__Type_of,
        'priceExtensionType' => \%priceExtensionType_of,
        'priceQualifier' => \%priceQualifier_of,
        'trackingUrlTemplate' => \%trackingUrlTemplate_of,
        'language' => \%language_of,
        'tableRows' => \%tableRows_of,
    },
    {
        'feedId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'feedItemId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'status' => 'Google::Ads::AdWords::v201802::FeedItem::Status',
        'feedType' => 'Google::Ads::AdWords::v201802::Feed::Type',
        'startTime' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'endTime' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'devicePreference' => 'Google::Ads::AdWords::v201802::FeedItemDevicePreference',
        'scheduling' => 'Google::Ads::AdWords::v201802::FeedItemScheduling',
        'campaignTargeting' => 'Google::Ads::AdWords::v201802::FeedItemCampaignTargeting',
        'adGroupTargeting' => 'Google::Ads::AdWords::v201802::FeedItemAdGroupTargeting',
        'keywordTargeting' => 'Google::Ads::AdWords::v201802::Keyword',
        'geoTargeting' => 'Google::Ads::AdWords::v201802::Location',
        'geoTargetingRestriction' => 'Google::Ads::AdWords::v201802::FeedItemGeoRestriction',
        'policyData' => 'Google::Ads::AdWords::v201802::FeedItemPolicyData',
        'ExtensionFeedItem__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'priceExtensionType' => 'Google::Ads::AdWords::v201802::PriceExtensionType',
        'priceQualifier' => 'Google::Ads::AdWords::v201802::PriceExtensionPriceQualifier',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'language' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'tableRows' => 'Google::Ads::AdWords::v201802::PriceTableRow',
    },
    {

        'feedId' => 'feedId',
        'feedItemId' => 'feedItemId',
        'status' => 'status',
        'feedType' => 'feedType',
        'startTime' => 'startTime',
        'endTime' => 'endTime',
        'devicePreference' => 'devicePreference',
        'scheduling' => 'scheduling',
        'campaignTargeting' => 'campaignTargeting',
        'adGroupTargeting' => 'adGroupTargeting',
        'keywordTargeting' => 'keywordTargeting',
        'geoTargeting' => 'geoTargeting',
        'geoTargetingRestriction' => 'geoTargetingRestriction',
        'policyData' => 'policyData',
        'ExtensionFeedItem__Type' => 'ExtensionFeedItem.Type',
        'priceExtensionType' => 'priceExtensionType',
        'priceQualifier' => 'priceQualifier',
        'trackingUrlTemplate' => 'trackingUrlTemplate',
        'language' => 'language',
        'tableRows' => 'tableRows',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201802::PriceFeedItem

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
PriceFeedItem from the namespace https://adwords.google.com/api/adwords/cm/v201802.

Represents a price extension. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * priceExtensionType


=item * priceQualifier


=item * trackingUrlTemplate


=item * language


=item * tableRows




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

