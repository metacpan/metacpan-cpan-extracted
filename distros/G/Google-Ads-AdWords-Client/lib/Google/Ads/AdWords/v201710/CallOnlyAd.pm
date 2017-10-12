package Google::Ads::AdWords::v201710::CallOnlyAd;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201710' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201710::Ad);
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
my %urlCustomParameters_of :ATTR(:get<urlCustomParameters>);
my %urlData_of :ATTR(:get<urlData>);
my %automated_of :ATTR(:get<automated>);
my %type_of :ATTR(:get<type>);
my %devicePreference_of :ATTR(:get<devicePreference>);
my %Ad__Type_of :ATTR(:get<Ad__Type>);
my %countryCode_of :ATTR(:get<countryCode>);
my %phoneNumber_of :ATTR(:get<phoneNumber>);
my %businessName_of :ATTR(:get<businessName>);
my %description1_of :ATTR(:get<description1>);
my %description2_of :ATTR(:get<description2>);
my %callTracked_of :ATTR(:get<callTracked>);
my %disableCallConversion_of :ATTR(:get<disableCallConversion>);
my %conversionTypeId_of :ATTR(:get<conversionTypeId>);
my %phoneNumberVerificationUrl_of :ATTR(:get<phoneNumberVerificationUrl>);

__PACKAGE__->_factory(
    [ qw(        id
        url
        displayUrl
        finalUrls
        finalMobileUrls
        finalAppUrls
        trackingUrlTemplate
        urlCustomParameters
        urlData
        automated
        type
        devicePreference
        Ad__Type
        countryCode
        phoneNumber
        businessName
        description1
        description2
        callTracked
        disableCallConversion
        conversionTypeId
        phoneNumberVerificationUrl

    ) ],
    {
        'id' => \%id_of,
        'url' => \%url_of,
        'displayUrl' => \%displayUrl_of,
        'finalUrls' => \%finalUrls_of,
        'finalMobileUrls' => \%finalMobileUrls_of,
        'finalAppUrls' => \%finalAppUrls_of,
        'trackingUrlTemplate' => \%trackingUrlTemplate_of,
        'urlCustomParameters' => \%urlCustomParameters_of,
        'urlData' => \%urlData_of,
        'automated' => \%automated_of,
        'type' => \%type_of,
        'devicePreference' => \%devicePreference_of,
        'Ad__Type' => \%Ad__Type_of,
        'countryCode' => \%countryCode_of,
        'phoneNumber' => \%phoneNumber_of,
        'businessName' => \%businessName_of,
        'description1' => \%description1_of,
        'description2' => \%description2_of,
        'callTracked' => \%callTracked_of,
        'disableCallConversion' => \%disableCallConversion_of,
        'conversionTypeId' => \%conversionTypeId_of,
        'phoneNumberVerificationUrl' => \%phoneNumberVerificationUrl_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'displayUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalMobileUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalAppUrls' => 'Google::Ads::AdWords::v201710::AppUrl',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'urlCustomParameters' => 'Google::Ads::AdWords::v201710::CustomParameters',
        'urlData' => 'Google::Ads::AdWords::v201710::UrlData',
        'automated' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'type' => 'Google::Ads::AdWords::v201710::Ad::Type',
        'devicePreference' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'Ad__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'countryCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'phoneNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'businessName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'callTracked' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'disableCallConversion' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'conversionTypeId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'phoneNumberVerificationUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'id' => 'id',
        'url' => 'url',
        'displayUrl' => 'displayUrl',
        'finalUrls' => 'finalUrls',
        'finalMobileUrls' => 'finalMobileUrls',
        'finalAppUrls' => 'finalAppUrls',
        'trackingUrlTemplate' => 'trackingUrlTemplate',
        'urlCustomParameters' => 'urlCustomParameters',
        'urlData' => 'urlData',
        'automated' => 'automated',
        'type' => 'type',
        'devicePreference' => 'devicePreference',
        'Ad__Type' => 'Ad.Type',
        'countryCode' => 'countryCode',
        'phoneNumber' => 'phoneNumber',
        'businessName' => 'businessName',
        'description1' => 'description1',
        'description2' => 'description2',
        'callTracked' => 'callTracked',
        'disableCallConversion' => 'disableCallConversion',
        'conversionTypeId' => 'conversionTypeId',
        'phoneNumberVerificationUrl' => 'phoneNumberVerificationUrl',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201710::CallOnlyAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CallOnlyAd from the namespace https://adwords.google.com/api/adwords/cm/v201710.

Represents a CallOnlyAd. <p class="caution"><b>Caution:</b> Call only ads do not use {@link #url url}, {@link #finalUrls finalUrls}, {@link #finalMobileUrls finalMobileUrls}, {@link #finalAppUrls finalAppUrls}, {@link #urlCustomParameters urlCustomParameters}, or {@link #trackingUrlTemplate trackingUrlTemplate}; setting these fields on a call only ad will cause an error. <span class="constraint AdxEnabled">This is enabled for AdX.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * countryCode


=item * phoneNumber


=item * businessName


=item * description1


=item * description2


=item * callTracked


=item * disableCallConversion


=item * conversionTypeId


=item * phoneNumberVerificationUrl




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

