package Google::Ads::AdWords::v201609::ReviewFeedItem;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201609' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201609::ExtensionFeedItem);
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
my %reviewText_of :ATTR(:get<reviewText>);
my %reviewSourceName_of :ATTR(:get<reviewSourceName>);
my %reviewSourceUrl_of :ATTR(:get<reviewSourceUrl>);
my %reviewTextExactlyQuoted_of :ATTR(:get<reviewTextExactlyQuoted>);

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
        reviewText
        reviewSourceName
        reviewSourceUrl
        reviewTextExactlyQuoted

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
        'reviewText' => \%reviewText_of,
        'reviewSourceName' => \%reviewSourceName_of,
        'reviewSourceUrl' => \%reviewSourceUrl_of,
        'reviewTextExactlyQuoted' => \%reviewTextExactlyQuoted_of,
    },
    {
        'feedId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'feedItemId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'status' => 'Google::Ads::AdWords::v201609::FeedItem::Status',
        'feedType' => 'Google::Ads::AdWords::v201609::Feed::Type',
        'startTime' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'endTime' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'devicePreference' => 'Google::Ads::AdWords::v201609::FeedItemDevicePreference',
        'scheduling' => 'Google::Ads::AdWords::v201609::FeedItemScheduling',
        'campaignTargeting' => 'Google::Ads::AdWords::v201609::FeedItemCampaignTargeting',
        'adGroupTargeting' => 'Google::Ads::AdWords::v201609::FeedItemAdGroupTargeting',
        'keywordTargeting' => 'Google::Ads::AdWords::v201609::Keyword',
        'geoTargeting' => 'Google::Ads::AdWords::v201609::Location',
        'geoTargetingRestriction' => 'Google::Ads::AdWords::v201609::FeedItemGeoRestriction',
        'policyData' => 'Google::Ads::AdWords::v201609::FeedItemPolicyData',
        'ExtensionFeedItem__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'reviewText' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'reviewSourceName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'reviewSourceUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'reviewTextExactlyQuoted' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
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
        'reviewText' => 'reviewText',
        'reviewSourceName' => 'reviewSourceName',
        'reviewSourceUrl' => 'reviewSourceUrl',
        'reviewTextExactlyQuoted' => 'reviewTextExactlyQuoted',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201609::ReviewFeedItem

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ReviewFeedItem from the namespace https://adwords.google.com/api/adwords/cm/v201609.

Represents a Review extension. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * reviewText


=item * reviewSourceName


=item * reviewSourceUrl


=item * reviewTextExactlyQuoted




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

