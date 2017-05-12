package Google::Ads::AdWords::v201309::BiddableAdGroupCriterion;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201309' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201309::AdGroupCriterion);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %adGroupId_of :ATTR(:get<adGroupId>);
my %criterionUse_of :ATTR(:get<criterionUse>);
my %criterion_of :ATTR(:get<criterion>);
my %forwardCompatibilityMap_of :ATTR(:get<forwardCompatibilityMap>);
my %AdGroupCriterion__Type_of :ATTR(:get<AdGroupCriterion__Type>);
my %userStatus_of :ATTR(:get<userStatus>);
my %systemServingStatus_of :ATTR(:get<systemServingStatus>);
my %approvalStatus_of :ATTR(:get<approvalStatus>);
my %disapprovalReasons_of :ATTR(:get<disapprovalReasons>);
my %destinationUrl_of :ATTR(:get<destinationUrl>);
my %experimentData_of :ATTR(:get<experimentData>);
my %firstPageCpc_of :ATTR(:get<firstPageCpc>);
my %topOfPageCpc_of :ATTR(:get<topOfPageCpc>);
my %qualityInfo_of :ATTR(:get<qualityInfo>);
my %biddingStrategyConfiguration_of :ATTR(:get<biddingStrategyConfiguration>);
my %bidModifier_of :ATTR(:get<bidModifier>);

__PACKAGE__->_factory(
    [ qw(        adGroupId
        criterionUse
        criterion
        forwardCompatibilityMap
        AdGroupCriterion__Type
        userStatus
        systemServingStatus
        approvalStatus
        disapprovalReasons
        destinationUrl
        experimentData
        firstPageCpc
        topOfPageCpc
        qualityInfo
        biddingStrategyConfiguration
        bidModifier

    ) ],
    {
        'adGroupId' => \%adGroupId_of,
        'criterionUse' => \%criterionUse_of,
        'criterion' => \%criterion_of,
        'forwardCompatibilityMap' => \%forwardCompatibilityMap_of,
        'AdGroupCriterion__Type' => \%AdGroupCriterion__Type_of,
        'userStatus' => \%userStatus_of,
        'systemServingStatus' => \%systemServingStatus_of,
        'approvalStatus' => \%approvalStatus_of,
        'disapprovalReasons' => \%disapprovalReasons_of,
        'destinationUrl' => \%destinationUrl_of,
        'experimentData' => \%experimentData_of,
        'firstPageCpc' => \%firstPageCpc_of,
        'topOfPageCpc' => \%topOfPageCpc_of,
        'qualityInfo' => \%qualityInfo_of,
        'biddingStrategyConfiguration' => \%biddingStrategyConfiguration_of,
        'bidModifier' => \%bidModifier_of,
    },
    {
        'adGroupId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'criterionUse' => 'Google::Ads::AdWords::v201309::CriterionUse',
        'criterion' => 'Google::Ads::AdWords::v201309::Criterion',
        'forwardCompatibilityMap' => 'Google::Ads::AdWords::v201309::String_StringMapEntry',
        'AdGroupCriterion__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'userStatus' => 'Google::Ads::AdWords::v201309::UserStatus',
        'systemServingStatus' => 'Google::Ads::AdWords::v201309::SystemServingStatus',
        'approvalStatus' => 'Google::Ads::AdWords::v201309::ApprovalStatus',
        'disapprovalReasons' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'destinationUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'experimentData' => 'Google::Ads::AdWords::v201309::BiddableAdGroupCriterionExperimentData',
        'firstPageCpc' => 'Google::Ads::AdWords::v201309::Bid',
        'topOfPageCpc' => 'Google::Ads::AdWords::v201309::Bid',
        'qualityInfo' => 'Google::Ads::AdWords::v201309::QualityInfo',
        'biddingStrategyConfiguration' => 'Google::Ads::AdWords::v201309::BiddingStrategyConfiguration',
        'bidModifier' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
    },
    {

        'adGroupId' => 'adGroupId',
        'criterionUse' => 'criterionUse',
        'criterion' => 'criterion',
        'forwardCompatibilityMap' => 'forwardCompatibilityMap',
        'AdGroupCriterion__Type' => 'AdGroupCriterion.Type',
        'userStatus' => 'userStatus',
        'systemServingStatus' => 'systemServingStatus',
        'approvalStatus' => 'approvalStatus',
        'disapprovalReasons' => 'disapprovalReasons',
        'destinationUrl' => 'destinationUrl',
        'experimentData' => 'experimentData',
        'firstPageCpc' => 'firstPageCpc',
        'topOfPageCpc' => 'topOfPageCpc',
        'qualityInfo' => 'qualityInfo',
        'biddingStrategyConfiguration' => 'biddingStrategyConfiguration',
        'bidModifier' => 'bidModifier',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201309::BiddableAdGroupCriterion

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
BiddableAdGroupCriterion from the namespace https://adwords.google.com/api/adwords/cm/v201309.

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


=item * qualityInfo


=item * biddingStrategyConfiguration


=item * bidModifier




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

