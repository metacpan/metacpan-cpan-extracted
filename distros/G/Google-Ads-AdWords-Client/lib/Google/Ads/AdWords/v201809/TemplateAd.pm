package Google::Ads::AdWords::v201809::TemplateAd;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201809' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201809::Ad);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %url_of :ATTR(:get<url>);
my %displayUrl_of :ATTR(:get<displayUrl>);
my %finalUrls_of :ATTR(:get<finalUrls>);
my %finalMobileUrls_of :ATTR(:get<finalMobileUrls>);
my %finalAppUrls_of :ATTR(:get<finalAppUrls>);
my %trackingUrlTemplate_of :ATTR(:get<trackingUrlTemplate>);
my %finalUrlSuffix_of :ATTR(:get<finalUrlSuffix>);
my %urlCustomParameters_of :ATTR(:get<urlCustomParameters>);
my %urlData_of :ATTR(:get<urlData>);
my %automated_of :ATTR(:get<automated>);
my %type_of :ATTR(:get<type>);
my %devicePreference_of :ATTR(:get<devicePreference>);
my %systemManagedEntitySource_of :ATTR(:get<systemManagedEntitySource>);
my %Ad__Type_of :ATTR(:get<Ad__Type>);
my %templateId_of :ATTR(:get<templateId>);
my %adUnionId_of :ATTR(:get<adUnionId>);
my %templateElements_of :ATTR(:get<templateElements>);
my %adAsImage_of :ATTR(:get<adAsImage>);
my %dimensions_of :ATTR(:get<dimensions>);
my %name_of :ATTR(:get<name>);
my %duration_of :ATTR(:get<duration>);
my %originAdId_of :ATTR(:get<originAdId>);

__PACKAGE__->_factory(
    [ qw(        id
        url
        displayUrl
        finalUrls
        finalMobileUrls
        finalAppUrls
        trackingUrlTemplate
        finalUrlSuffix
        urlCustomParameters
        urlData
        automated
        type
        devicePreference
        systemManagedEntitySource
        Ad__Type
        templateId
        adUnionId
        templateElements
        adAsImage
        dimensions
        name
        duration
        originAdId

    ) ],
    {
        'id' => \%id_of,
        'url' => \%url_of,
        'displayUrl' => \%displayUrl_of,
        'finalUrls' => \%finalUrls_of,
        'finalMobileUrls' => \%finalMobileUrls_of,
        'finalAppUrls' => \%finalAppUrls_of,
        'trackingUrlTemplate' => \%trackingUrlTemplate_of,
        'finalUrlSuffix' => \%finalUrlSuffix_of,
        'urlCustomParameters' => \%urlCustomParameters_of,
        'urlData' => \%urlData_of,
        'automated' => \%automated_of,
        'type' => \%type_of,
        'devicePreference' => \%devicePreference_of,
        'systemManagedEntitySource' => \%systemManagedEntitySource_of,
        'Ad__Type' => \%Ad__Type_of,
        'templateId' => \%templateId_of,
        'adUnionId' => \%adUnionId_of,
        'templateElements' => \%templateElements_of,
        'adAsImage' => \%adAsImage_of,
        'dimensions' => \%dimensions_of,
        'name' => \%name_of,
        'duration' => \%duration_of,
        'originAdId' => \%originAdId_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'displayUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalMobileUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalAppUrls' => 'Google::Ads::AdWords::v201809::AppUrl',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrlSuffix' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'urlCustomParameters' => 'Google::Ads::AdWords::v201809::CustomParameters',
        'urlData' => 'Google::Ads::AdWords::v201809::UrlData',
        'automated' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'type' => 'Google::Ads::AdWords::v201809::Ad::Type',
        'devicePreference' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'systemManagedEntitySource' => 'Google::Ads::AdWords::v201809::SystemManagedEntitySource',
        'Ad__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'templateId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'adUnionId' => 'Google::Ads::AdWords::v201809::AdUnionId',
        'templateElements' => 'Google::Ads::AdWords::v201809::TemplateElement',
        'adAsImage' => 'Google::Ads::AdWords::v201809::Image',
        'dimensions' => 'Google::Ads::AdWords::v201809::Dimensions',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'duration' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'originAdId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
    },
    {

        'id' => 'id',
        'url' => 'url',
        'displayUrl' => 'displayUrl',
        'finalUrls' => 'finalUrls',
        'finalMobileUrls' => 'finalMobileUrls',
        'finalAppUrls' => 'finalAppUrls',
        'trackingUrlTemplate' => 'trackingUrlTemplate',
        'finalUrlSuffix' => 'finalUrlSuffix',
        'urlCustomParameters' => 'urlCustomParameters',
        'urlData' => 'urlData',
        'automated' => 'automated',
        'type' => 'type',
        'devicePreference' => 'devicePreference',
        'systemManagedEntitySource' => 'systemManagedEntitySource',
        'Ad__Type' => 'Ad.Type',
        'templateId' => 'templateId',
        'adUnionId' => 'adUnionId',
        'templateElements' => 'templateElements',
        'adAsImage' => 'adAsImage',
        'dimensions' => 'dimensions',
        'name' => 'name',
        'duration' => 'duration',
        'originAdId' => 'originAdId',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201809::TemplateAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
TemplateAd from the namespace https://adwords.google.com/api/adwords/cm/v201809.

Represents a <a href= "//www.google.com/adwords/displaynetwork/plan-creative-campaigns/display-ad-builder.html" >Display Ad Builder</a> template ad. A template ad is composed of a template (specified by its ID) and the data that populates the template's fields. For a list of available templates and their required fields, see <a href="/adwords/api/docs/appendix/templateads">Template Ads</a>. <span class="constraint AdxEnabled">This is disabled for AdX when it is contained within Operators: ADD, SET.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * templateId


=item * adUnionId


=item * templateElements


=item * adAsImage


=item * dimensions


=item * name


=item * duration


=item * originAdId




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

