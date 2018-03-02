package Google::Ads::AdWords::v201802::GmailAd;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201802' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201802::Ad);
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
my %teaser_of :ATTR(:get<teaser>);
my %headerImage_of :ATTR(:get<headerImage>);
my %marketingImage_of :ATTR(:get<marketingImage>);
my %marketingImageHeadline_of :ATTR(:get<marketingImageHeadline>);
my %marketingImageDescription_of :ATTR(:get<marketingImageDescription>);
my %marketingImageDisplayCallToAction_of :ATTR(:get<marketingImageDisplayCallToAction>);
my %productImages_of :ATTR(:get<productImages>);
my %productVideoList_of :ATTR(:get<productVideoList>);

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
        teaser
        headerImage
        marketingImage
        marketingImageHeadline
        marketingImageDescription
        marketingImageDisplayCallToAction
        productImages
        productVideoList

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
        'teaser' => \%teaser_of,
        'headerImage' => \%headerImage_of,
        'marketingImage' => \%marketingImage_of,
        'marketingImageHeadline' => \%marketingImageHeadline_of,
        'marketingImageDescription' => \%marketingImageDescription_of,
        'marketingImageDisplayCallToAction' => \%marketingImageDisplayCallToAction_of,
        'productImages' => \%productImages_of,
        'productVideoList' => \%productVideoList_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'displayUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalMobileUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalAppUrls' => 'Google::Ads::AdWords::v201802::AppUrl',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrlSuffix' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'urlCustomParameters' => 'Google::Ads::AdWords::v201802::CustomParameters',
        'urlData' => 'Google::Ads::AdWords::v201802::UrlData',
        'automated' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'type' => 'Google::Ads::AdWords::v201802::Ad::Type',
        'devicePreference' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'systemManagedEntitySource' => 'Google::Ads::AdWords::v201802::SystemManagedEntitySource',
        'Ad__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'teaser' => 'Google::Ads::AdWords::v201802::GmailTeaser',
        'headerImage' => 'Google::Ads::AdWords::v201802::Image',
        'marketingImage' => 'Google::Ads::AdWords::v201802::Image',
        'marketingImageHeadline' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'marketingImageDescription' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'marketingImageDisplayCallToAction' => 'Google::Ads::AdWords::v201802::DisplayCallToAction',
        'productImages' => 'Google::Ads::AdWords::v201802::ProductImage',
        'productVideoList' => 'Google::Ads::AdWords::v201802::Video',
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
        'teaser' => 'teaser',
        'headerImage' => 'headerImage',
        'marketingImage' => 'marketingImage',
        'marketingImageHeadline' => 'marketingImageHeadline',
        'marketingImageDescription' => 'marketingImageDescription',
        'marketingImageDisplayCallToAction' => 'marketingImageDisplayCallToAction',
        'productImages' => 'productImages',
        'productVideoList' => 'productVideoList',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201802::GmailAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
GmailAd from the namespace https://adwords.google.com/api/adwords/cm/v201802.

Represents Gmail ad. <p class="caution"><b>Caution:</b> Gmail ads do not use {@link #url url}, {@link #displayUrl displayUrl}, {@link #finalAppUrls finalAppUrls}, or {@link #devicePreference devicePreference}; Setting these fields on a Gmail ad will cause an error. <span class="constraint AdxEnabled">This is enabled for AdX.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * teaser


=item * headerImage


=item * marketingImage


=item * marketingImageHeadline


=item * marketingImageDescription


=item * marketingImageDisplayCallToAction


=item * productImages


=item * productVideoList




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

