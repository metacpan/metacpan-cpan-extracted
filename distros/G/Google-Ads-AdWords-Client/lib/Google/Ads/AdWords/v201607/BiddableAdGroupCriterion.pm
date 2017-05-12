package Google::Ads::AdWords::v201607::BiddableAdGroupCriterion;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201607' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201607::AdGroupCriterion);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

{ # BLOCK to scope variables

my %adGroupId_of :ATTR(:get<adGroupId>);
my %criterionUse_of :ATTR(:get<criterionUse>);
my %criterion_of :ATTR(:get<criterion>);
my %labels_of :ATTR(:get<labels>);
my %forwardCompatibilityMap_of :ATTR(:get<forwardCompatibilityMap>);
my %baseCampaignId_of :ATTR(:get<baseCampaignId>);
my %baseAdGroupId_of :ATTR(:get<baseAdGroupId>);
my %AdGroupCriterion__Type_of :ATTR(:get<AdGroupCriterion__Type>);
my %userStatus_of :ATTR(:get<userStatus>);
my %systemServingStatus_of :ATTR(:get<systemServingStatus>);
my %approvalStatus_of :ATTR(:get<approvalStatus>);
my %disapprovalReasons_of :ATTR(:get<disapprovalReasons>);
my %destinationUrl_of :ATTR(:get<destinationUrl>);
my %experimentData_of :ATTR(:get<experimentData>);
my %firstPageCpc_of :ATTR(:get<firstPageCpc>);
my %topOfPageCpc_of :ATTR(:get<topOfPageCpc>);
my %firstPositionCpc_of :ATTR(:get<firstPositionCpc>);
my %qualityInfo_of :ATTR(:get<qualityInfo>);
my %biddingStrategyConfiguration_of :ATTR(:get<biddingStrategyConfiguration>);
my %bidModifier_of :ATTR(:get<bidModifier>);
my %finalUrls_of :ATTR(:get<finalUrls>);
my %finalMobileUrls_of :ATTR(:get<finalMobileUrls>);
my %finalAppUrls_of :ATTR(:get<finalAppUrls>);
my %trackingUrlTemplate_of :ATTR(:get<trackingUrlTemplate>);
my %urlCustomParameters_of :ATTR(:get<urlCustomParameters>);

__PACKAGE__->_factory(
    [ qw(        adGroupId
        criterionUse
        criterion
        labels
        forwardCompatibilityMap
        baseCampaignId
        baseAdGroupId
        AdGroupCriterion__Type
        userStatus
        systemServingStatus
        approvalStatus
        disapprovalReasons
        destinationUrl
        experimentData
        firstPageCpc
        topOfPageCpc
        firstPositionCpc
        qualityInfo
        biddingStrategyConfiguration
        bidModifier
        finalUrls
        finalMobileUrls
        finalAppUrls
        trackingUrlTemplate
        urlCustomParameters

    ) ],
    {
        'adGroupId' => \%adGroupId_of,
        'criterionUse' => \%criterionUse_of,
        'criterion' => \%criterion_of,
        'labels' => \%labels_of,
        'forwardCompatibilityMap' => \%forwardCompatibilityMap_of,
        'baseCampaignId' => \%baseCampaignId_of,
        'baseAdGroupId' => \%baseAdGroupId_of,
        'AdGroupCriterion__Type' => \%AdGroupCriterion__Type_of,
        'userStatus' => \%userStatus_of,
        'systemServingStatus' => \%systemServingStatus_of,
        'approvalStatus' => \%approvalStatus_of,
        'disapprovalReasons' => \%disapprovalReasons_of,
        'destinationUrl' => \%destinationUrl_of,
        'experimentData' => \%experimentData_of,
        'firstPageCpc' => \%firstPageCpc_of,
        'topOfPageCpc' => \%topOfPageCpc_of,
        'firstPositionCpc' => \%firstPositionCpc_of,
        'qualityInfo' => \%qualityInfo_of,
        'biddingStrategyConfiguration' => \%biddingStrategyConfiguration_of,
        'bidModifier' => \%bidModifier_of,
        'finalUrls' => \%finalUrls_of,
        'finalMobileUrls' => \%finalMobileUrls_of,
        'finalAppUrls' => \%finalAppUrls_of,
        'trackingUrlTemplate' => \%trackingUrlTemplate_of,
        'urlCustomParameters' => \%urlCustomParameters_of,
    },
    {
        'adGroupId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'criterionUse' => 'Google::Ads::AdWords::v201607::CriterionUse',
        'criterion' => 'Google::Ads::AdWords::v201607::Criterion',
        'labels' => 'Google::Ads::AdWords::v201607::Label',
        'forwardCompatibilityMap' => 'Google::Ads::AdWords::v201607::String_StringMapEntry',
        'baseCampaignId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'baseAdGroupId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'AdGroupCriterion__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'userStatus' => 'Google::Ads::AdWords::v201607::UserStatus',
        'systemServingStatus' => 'Google::Ads::AdWords::v201607::SystemServingStatus',
        'approvalStatus' => 'Google::Ads::AdWords::v201607::ApprovalStatus',
        'disapprovalReasons' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'destinationUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'experimentData' => 'Google::Ads::AdWords::v201607::BiddableAdGroupCriterionExperimentData',
        'firstPageCpc' => 'Google::Ads::AdWords::v201607::Bid',
        'topOfPageCpc' => 'Google::Ads::AdWords::v201607::Bid',
        'firstPositionCpc' => 'Google::Ads::AdWords::v201607::Bid',
        'qualityInfo' => 'Google::Ads::AdWords::v201607::QualityInfo',
        'biddingStrategyConfiguration' => 'Google::Ads::AdWords::v201607::BiddingStrategyConfiguration',
        'bidModifier' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
        'finalUrls' => 'Google::Ads::AdWords::v201607::UrlList',
        'finalMobileUrls' => 'Google::Ads::AdWords::v201607::UrlList',
        'finalAppUrls' => 'Google::Ads::AdWords::v201607::AppUrlList',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'urlCustomParameters' => 'Google::Ads::AdWords::v201607::CustomParameters',
    },
    {

        'adGroupId' => 'adGroupId',
        'criterionUse' => 'criterionUse',
        'criterion' => 'criterion',
        'labels' => 'labels',
        'forwardCompatibilityMap' => 'forwardCompatibilityMap',
        'baseCampaignId' => 'baseCampaignId',
        'baseAdGroupId' => 'baseAdGroupId',
        'AdGroupCriterion__Type' => 'AdGroupCriterion.Type',
        'userStatus' => 'userStatus',
        'systemServingStatus' => 'systemServingStatus',
        'approvalStatus' => 'approvalStatus',
        'disapprovalReasons' => 'disapprovalReasons',
        'destinationUrl' => 'destinationUrl',
        'experimentData' => 'experimentData',
        'firstPageCpc' => 'firstPageCpc',
        'topOfPageCpc' => 'topOfPageCpc',
        'firstPositionCpc' => 'firstPositionCpc',
        'qualityInfo' => 'qualityInfo',
        'biddingStrategyConfiguration' => 'biddingStrategyConfiguration',
        'bidModifier' => 'bidModifier',
        'finalUrls' => 'finalUrls',
        'finalMobileUrls' => 'finalMobileUrls',
        'finalAppUrls' => 'finalAppUrls',
        'trackingUrlTemplate' => 'trackingUrlTemplate',
        'urlCustomParameters' => 'urlCustomParameters',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201607::BiddableAdGroupCriterion

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
BiddableAdGroupCriterion from the namespace https://adwords.google.com/api/adwords/cm/v201607.

A biddable (positive) criterion in an adgroup. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * userStatus


=item * systemServingStatus


=item * approvalStatus


=item * disapprovalReasons


=item * destinationUrl


=item * experimentData


=item * firstPageCpc


=item * topOfPageCpc


=item * firstPositionCpc


=item * qualityInfo


=item * biddingStrategyConfiguration


=item * bidModifier


=item * finalUrls


=item * finalMobileUrls


=item * finalAppUrls


=item * trackingUrlTemplate


=item * urlCustomParameters




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

