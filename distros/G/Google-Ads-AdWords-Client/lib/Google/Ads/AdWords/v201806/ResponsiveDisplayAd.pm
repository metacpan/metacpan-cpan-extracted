package Google::Ads::AdWords::v201806::ResponsiveDisplayAd;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201806' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201806::Ad);
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
my %marketingImage_of :ATTR(:get<marketingImage>);
my %logoImage_of :ATTR(:get<logoImage>);
my %squareMarketingImage_of :ATTR(:get<squareMarketingImage>);
my %shortHeadline_of :ATTR(:get<shortHeadline>);
my %longHeadline_of :ATTR(:get<longHeadline>);
my %description_of :ATTR(:get<description>);
my %businessName_of :ATTR(:get<businessName>);
my %mainColor_of :ATTR(:get<mainColor>);
my %accentColor_of :ATTR(:get<accentColor>);
my %allowFlexibleColor_of :ATTR(:get<allowFlexibleColor>);
my %callToActionText_of :ATTR(:get<callToActionText>);
my %dynamicDisplayAdSettings_of :ATTR(:get<dynamicDisplayAdSettings>);
my %formatSetting_of :ATTR(:get<formatSetting>);

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
        marketingImage
        logoImage
        squareMarketingImage
        shortHeadline
        longHeadline
        description
        businessName
        mainColor
        accentColor
        allowFlexibleColor
        callToActionText
        dynamicDisplayAdSettings
        formatSetting

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
        'marketingImage' => \%marketingImage_of,
        'logoImage' => \%logoImage_of,
        'squareMarketingImage' => \%squareMarketingImage_of,
        'shortHeadline' => \%shortHeadline_of,
        'longHeadline' => \%longHeadline_of,
        'description' => \%description_of,
        'businessName' => \%businessName_of,
        'mainColor' => \%mainColor_of,
        'accentColor' => \%accentColor_of,
        'allowFlexibleColor' => \%allowFlexibleColor_of,
        'callToActionText' => \%callToActionText_of,
        'dynamicDisplayAdSettings' => \%dynamicDisplayAdSettings_of,
        'formatSetting' => \%formatSetting_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'displayUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalMobileUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalAppUrls' => 'Google::Ads::AdWords::v201806::AppUrl',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrlSuffix' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'urlCustomParameters' => 'Google::Ads::AdWords::v201806::CustomParameters',
        'urlData' => 'Google::Ads::AdWords::v201806::UrlData',
        'automated' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'type' => 'Google::Ads::AdWords::v201806::Ad::Type',
        'devicePreference' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'systemManagedEntitySource' => 'Google::Ads::AdWords::v201806::SystemManagedEntitySource',
        'Ad__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'marketingImage' => 'Google::Ads::AdWords::v201806::Image',
        'logoImage' => 'Google::Ads::AdWords::v201806::Image',
        'squareMarketingImage' => 'Google::Ads::AdWords::v201806::Image',
        'shortHeadline' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'longHeadline' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'businessName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'mainColor' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'accentColor' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'allowFlexibleColor' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'callToActionText' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'dynamicDisplayAdSettings' => 'Google::Ads::AdWords::v201806::DynamicSettings',
        'formatSetting' => 'Google::Ads::AdWords::v201806::DisplayAdFormatSetting',
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
        'marketingImage' => 'marketingImage',
        'logoImage' => 'logoImage',
        'squareMarketingImage' => 'squareMarketingImage',
        'shortHeadline' => 'shortHeadline',
        'longHeadline' => 'longHeadline',
        'description' => 'description',
        'businessName' => 'businessName',
        'mainColor' => 'mainColor',
        'accentColor' => 'accentColor',
        'allowFlexibleColor' => 'allowFlexibleColor',
        'callToActionText' => 'callToActionText',
        'dynamicDisplayAdSettings' => 'dynamicDisplayAdSettings',
        'formatSetting' => 'formatSetting',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201806::ResponsiveDisplayAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ResponsiveDisplayAd from the namespace https://adwords.google.com/api/adwords/cm/v201806.

Enhanced display ad format. <p class="caution"><b>Caution:</b> Responsive display ads do not use {@link #url url}, {@link #displayUrl displayUrl}, {@link #finalAppUrls finalAppUrls}, or {@link #devicePreference devicePreference}; setting these fields on a responsive display ad will cause an error. <span class="constraint AdxEnabled">This is enabled for AdX.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * marketingImage


=item * logoImage


=item * squareMarketingImage


=item * shortHeadline


=item * longHeadline


=item * description


=item * businessName


=item * mainColor


=item * accentColor


=item * allowFlexibleColor


=item * callToActionText


=item * dynamicDisplayAdSettings


=item * formatSetting




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

