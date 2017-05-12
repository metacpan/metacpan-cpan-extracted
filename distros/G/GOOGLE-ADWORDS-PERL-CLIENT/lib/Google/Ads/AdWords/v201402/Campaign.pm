package Google::Ads::AdWords::v201402::Campaign;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201402' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %name_of :ATTR(:get<name>);
my %status_of :ATTR(:get<status>);
my %servingStatus_of :ATTR(:get<servingStatus>);
my %startDate_of :ATTR(:get<startDate>);
my %endDate_of :ATTR(:get<endDate>);
my %budget_of :ATTR(:get<budget>);
my %conversionOptimizerEligibility_of :ATTR(:get<conversionOptimizerEligibility>);
my %adServingOptimizationStatus_of :ATTR(:get<adServingOptimizationStatus>);
my %frequencyCap_of :ATTR(:get<frequencyCap>);
my %settings_of :ATTR(:get<settings>);
my %advertisingChannelType_of :ATTR(:get<advertisingChannelType>);
my %networkSetting_of :ATTR(:get<networkSetting>);
my %biddingStrategyConfiguration_of :ATTR(:get<biddingStrategyConfiguration>);
my %forwardCompatibilityMap_of :ATTR(:get<forwardCompatibilityMap>);
my %displaySelect_of :ATTR(:get<displaySelect>);

__PACKAGE__->_factory(
    [ qw(        id
        name
        status
        servingStatus
        startDate
        endDate
        budget
        conversionOptimizerEligibility
        adServingOptimizationStatus
        frequencyCap
        settings
        advertisingChannelType
        networkSetting
        biddingStrategyConfiguration
        forwardCompatibilityMap
        displaySelect

    ) ],
    {
        'id' => \%id_of,
        'name' => \%name_of,
        'status' => \%status_of,
        'servingStatus' => \%servingStatus_of,
        'startDate' => \%startDate_of,
        'endDate' => \%endDate_of,
        'budget' => \%budget_of,
        'conversionOptimizerEligibility' => \%conversionOptimizerEligibility_of,
        'adServingOptimizationStatus' => \%adServingOptimizationStatus_of,
        'frequencyCap' => \%frequencyCap_of,
        'settings' => \%settings_of,
        'advertisingChannelType' => \%advertisingChannelType_of,
        'networkSetting' => \%networkSetting_of,
        'biddingStrategyConfiguration' => \%biddingStrategyConfiguration_of,
        'forwardCompatibilityMap' => \%forwardCompatibilityMap_of,
        'displaySelect' => \%displaySelect_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'status' => 'Google::Ads::AdWords::v201402::CampaignStatus',
        'servingStatus' => 'Google::Ads::AdWords::v201402::ServingStatus',
        'startDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'endDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'budget' => 'Google::Ads::AdWords::v201402::Budget',
        'conversionOptimizerEligibility' => 'Google::Ads::AdWords::v201402::ConversionOptimizerEligibility',
        'adServingOptimizationStatus' => 'Google::Ads::AdWords::v201402::AdServingOptimizationStatus',
        'frequencyCap' => 'Google::Ads::AdWords::v201402::FrequencyCap',
        'settings' => 'Google::Ads::AdWords::v201402::Setting',
        'advertisingChannelType' => 'Google::Ads::AdWords::v201402::AdvertisingChannelType',
        'networkSetting' => 'Google::Ads::AdWords::v201402::NetworkSetting',
        'biddingStrategyConfiguration' => 'Google::Ads::AdWords::v201402::BiddingStrategyConfiguration',
        'forwardCompatibilityMap' => 'Google::Ads::AdWords::v201402::String_StringMapEntry',
        'displaySelect' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
    },
    {

        'id' => 'id',
        'name' => 'name',
        'status' => 'status',
        'servingStatus' => 'servingStatus',
        'startDate' => 'startDate',
        'endDate' => 'endDate',
        'budget' => 'budget',
        'conversionOptimizerEligibility' => 'conversionOptimizerEligibility',
        'adServingOptimizationStatus' => 'adServingOptimizationStatus',
        'frequencyCap' => 'frequencyCap',
        'settings' => 'settings',
        'advertisingChannelType' => 'advertisingChannelType',
        'networkSetting' => 'networkSetting',
        'biddingStrategyConfiguration' => 'biddingStrategyConfiguration',
        'forwardCompatibilityMap' => 'forwardCompatibilityMap',
        'displaySelect' => 'displaySelect',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201402::Campaign

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Campaign from the namespace https://adwords.google.com/api/adwords/cm/v201402.

Data representing an AdWords campaign. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * id


=item * name


=item * status


=item * servingStatus


=item * startDate


=item * endDate


=item * budget


=item * conversionOptimizerEligibility


=item * adServingOptimizationStatus


=item * frequencyCap


=item * settings


=item * advertisingChannelType


=item * networkSetting


=item * biddingStrategyConfiguration


=item * forwardCompatibilityMap


=item * displaySelect




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

