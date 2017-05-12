package Google::Ads::AdWords::v201607::SitelinkFeedItem;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201607' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201607::ExtensionFeedItem);
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
my %sitelinkText_of :ATTR(:get<sitelinkText>);
my %sitelinkUrl_of :ATTR(:get<sitelinkUrl>);
my %sitelinkLine2_of :ATTR(:get<sitelinkLine2>);
my %sitelinkLine3_of :ATTR(:get<sitelinkLine3>);
my %sitelinkFinalUrls_of :ATTR(:get<sitelinkFinalUrls>);
my %sitelinkFinalMobileUrls_of :ATTR(:get<sitelinkFinalMobileUrls>);
my %sitelinkTrackingUrlTemplate_of :ATTR(:get<sitelinkTrackingUrlTemplate>);
my %sitelinkUrlCustomParameters_of :ATTR(:get<sitelinkUrlCustomParameters>);

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
        sitelinkText
        sitelinkUrl
        sitelinkLine2
        sitelinkLine3
        sitelinkFinalUrls
        sitelinkFinalMobileUrls
        sitelinkTrackingUrlTemplate
        sitelinkUrlCustomParameters

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
        'sitelinkText' => \%sitelinkText_of,
        'sitelinkUrl' => \%sitelinkUrl_of,
        'sitelinkLine2' => \%sitelinkLine2_of,
        'sitelinkLine3' => \%sitelinkLine3_of,
        'sitelinkFinalUrls' => \%sitelinkFinalUrls_of,
        'sitelinkFinalMobileUrls' => \%sitelinkFinalMobileUrls_of,
        'sitelinkTrackingUrlTemplate' => \%sitelinkTrackingUrlTemplate_of,
        'sitelinkUrlCustomParameters' => \%sitelinkUrlCustomParameters_of,
    },
    {
        'feedId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'feedItemId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'status' => 'Google::Ads::AdWords::v201607::FeedItem::Status',
        'feedType' => 'Google::Ads::AdWords::v201607::Feed::Type',
        'startTime' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'endTime' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'devicePreference' => 'Google::Ads::AdWords::v201607::FeedItemDevicePreference',
        'scheduling' => 'Google::Ads::AdWords::v201607::FeedItemScheduling',
        'campaignTargeting' => 'Google::Ads::AdWords::v201607::FeedItemCampaignTargeting',
        'adGroupTargeting' => 'Google::Ads::AdWords::v201607::FeedItemAdGroupTargeting',
        'keywordTargeting' => 'Google::Ads::AdWords::v201607::Keyword',
        'geoTargeting' => 'Google::Ads::AdWords::v201607::Location',
        'geoTargetingRestriction' => 'Google::Ads::AdWords::v201607::FeedItemGeoRestriction',
        'policyData' => 'Google::Ads::AdWords::v201607::FeedItemPolicyData',
        'ExtensionFeedItem__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'sitelinkText' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'sitelinkUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'sitelinkLine2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'sitelinkLine3' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'sitelinkFinalUrls' => 'Google::Ads::AdWords::v201607::UrlList',
        'sitelinkFinalMobileUrls' => 'Google::Ads::AdWords::v201607::UrlList',
        'sitelinkTrackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'sitelinkUrlCustomParameters' => 'Google::Ads::AdWords::v201607::CustomParameters',
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
        'sitelinkText' => 'sitelinkText',
        'sitelinkUrl' => 'sitelinkUrl',
        'sitelinkLine2' => 'sitelinkLine2',
        'sitelinkLine3' => 'sitelinkLine3',
        'sitelinkFinalUrls' => 'sitelinkFinalUrls',
        'sitelinkFinalMobileUrls' => 'sitelinkFinalMobileUrls',
        'sitelinkTrackingUrlTemplate' => 'sitelinkTrackingUrlTemplate',
        'sitelinkUrlCustomParameters' => 'sitelinkUrlCustomParameters',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201607::SitelinkFeedItem

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
SitelinkFeedItem from the namespace https://adwords.google.com/api/adwords/cm/v201607.

Represents a sitelink extension. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * sitelinkText


=item * sitelinkUrl


=item * sitelinkLine2


=item * sitelinkLine3


=item * sitelinkFinalUrls


=item * sitelinkFinalMobileUrls


=item * sitelinkTrackingUrlTemplate


=item * sitelinkUrlCustomParameters




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

