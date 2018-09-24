package Google::Ads::AdWords::v201809::UniversalAppAd;
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
my %headlines_of :ATTR(:get<headlines>);
my %descriptions_of :ATTR(:get<descriptions>);
my %mandatoryAdText_of :ATTR(:get<mandatoryAdText>);
my %images_of :ATTR(:get<images>);
my %videos_of :ATTR(:get<videos>);
my %html5MediaBundles_of :ATTR(:get<html5MediaBundles>);

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
        headlines
        descriptions
        mandatoryAdText
        images
        videos
        html5MediaBundles

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
        'headlines' => \%headlines_of,
        'descriptions' => \%descriptions_of,
        'mandatoryAdText' => \%mandatoryAdText_of,
        'images' => \%images_of,
        'videos' => \%videos_of,
        'html5MediaBundles' => \%html5MediaBundles_of,
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
        'headlines' => 'Google::Ads::AdWords::v201809::AssetLink',
        'descriptions' => 'Google::Ads::AdWords::v201809::AssetLink',
        'mandatoryAdText' => 'Google::Ads::AdWords::v201809::AssetLink',
        'images' => 'Google::Ads::AdWords::v201809::AssetLink',
        'videos' => 'Google::Ads::AdWords::v201809::AssetLink',
        'html5MediaBundles' => 'Google::Ads::AdWords::v201809::AssetLink',
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
        'headlines' => 'headlines',
        'descriptions' => 'descriptions',
        'mandatoryAdText' => 'mandatoryAdText',
        'images' => 'images',
        'videos' => 'videos',
        'html5MediaBundles' => 'html5MediaBundles',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201809::UniversalAppAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
UniversalAppAd from the namespace https://adwords.google.com/api/adwords/cm/v201809.

Represents a universal app ad <p class="caution"><b>Caution:</b> Universal app ads do not use #displayUrl displayUrl}, \{@link #finalAppUrls finalAppUrls}, or {@link #devicePreference devicePreference}; setting these fields on a universal app ad will cause an error. <span class="constraint AdxEnabled">This is enabled for AdX.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * headlines


=item * descriptions


=item * mandatoryAdText


=item * images


=item * videos


=item * html5MediaBundles




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

