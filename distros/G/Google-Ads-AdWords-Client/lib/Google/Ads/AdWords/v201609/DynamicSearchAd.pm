package Google::Ads::AdWords::v201609::DynamicSearchAd;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201609' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201609::Ad);
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
my %type_of :ATTR(:get<type>);
my %devicePreference_of :ATTR(:get<devicePreference>);
my %Ad__Type_of :ATTR(:get<Ad__Type>);
my %description1_of :ATTR(:get<description1>);
my %description2_of :ATTR(:get<description2>);

__PACKAGE__->_factory(
    [ qw(        id
        url
        displayUrl
        finalUrls
        finalMobileUrls
        finalAppUrls
        trackingUrlTemplate
        urlCustomParameters
        type
        devicePreference
        Ad__Type
        description1
        description2

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
        'type' => \%type_of,
        'devicePreference' => \%devicePreference_of,
        'Ad__Type' => \%Ad__Type_of,
        'description1' => \%description1_of,
        'description2' => \%description2_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'displayUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalMobileUrls' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'finalAppUrls' => 'Google::Ads::AdWords::v201609::AppUrl',
        'trackingUrlTemplate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'urlCustomParameters' => 'Google::Ads::AdWords::v201609::CustomParameters',
        'type' => 'Google::Ads::AdWords::v201609::Ad::Type',
        'devicePreference' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'Ad__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
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
        'type' => 'type',
        'devicePreference' => 'devicePreference',
        'Ad__Type' => 'Ad.Type',
        'description1' => 'description1',
        'description2' => 'description2',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201609::DynamicSearchAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
DynamicSearchAd from the namespace https://adwords.google.com/api/adwords/cm/v201609.

Represents a dynamic search ad. This ad will have its headline and tracking URL auto-generated at serving time according to domain name specific information provided by {@link DomainInfoExtension} linked at the campaign level. <p>Auto-generated fields: headline and optional tracking URL.</p> <p><b>Required fields:</b> {@code description1}, {@code description2}, {@code displayUrl}.</p> <p>The tracking URL field must contain at least one of the following placeholder tags (URL parameters):</p> <ul> <li>{unescapedlpurl}</li> <li>{escapedlpurl}</li> <li>{lpurl}</li> <li>{lpurl+2}</li> <li>{lpurl+3}</li> </ul> <ul> <li>{unescapedlpurl} will be replaced with the full landing page URL of the displayed ad. Extra query parameters can be added to the end, e.g.: "{unescapedlpurl}?lang=en".</li> <li>{escapedlpurl} will be replaced with the URL-encoded version of the full landing page URL. This makes it suitable for use as a query parameter value (e.g.: "http://www.3rdpartytracker.com/?lp={escapedlpurl}") but not at the beginning of the URL field.</li> <li>{lpurl} encodes the "?" and "=" of the landing page URL making it suitable for use as a query parameter. If found at the beginning of the URL field, it is replaced by the {unescapedlpurl} value. E.g.: "http://tracking.com/redir.php?tracking=xyz&url={lpurl}".</li> <li>{lpurl+2} and {lpurl+3} will be replaced with the landing page URL escaped two or three times, respectively. This makes it suitable if there is a chain of redirects in the tracking URL.</li> </ul> <p class="note">Note that {@code finalUrls} and {@code finalMobileUrls} cannot be set for dynamic search ads.</p> <p>For more information, see the article <a href="//support.google.com/adwords/answer/2549100">Using dynamic tracking URLs</a>. </p> <span class="constraint AdxEnabled">This is disabled for AdX when it is contained within Operators: ADD, SET.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * description1


=item * description2




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

