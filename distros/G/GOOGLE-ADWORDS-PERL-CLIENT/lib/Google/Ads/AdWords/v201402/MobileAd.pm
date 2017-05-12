package Google::Ads::AdWords::v201402::MobileAd;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201402' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201402::Ad);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %url_of :ATTR(:get<url>);
my %displayUrl_of :ATTR(:get<displayUrl>);
my %devicePreference_of :ATTR(:get<devicePreference>);
my %Ad__Type_of :ATTR(:get<Ad__Type>);
my %headline_of :ATTR(:get<headline>);
my %description_of :ATTR(:get<description>);
my %markupLanguages_of :ATTR(:get<markupLanguages>);
my %mobileCarriers_of :ATTR(:get<mobileCarriers>);
my %businessName_of :ATTR(:get<businessName>);
my %countryCode_of :ATTR(:get<countryCode>);
my %phoneNumber_of :ATTR(:get<phoneNumber>);

__PACKAGE__->_factory(
    [ qw(        id
        url
        displayUrl
        devicePreference
        Ad__Type
        headline
        description
        markupLanguages
        mobileCarriers
        businessName
        countryCode
        phoneNumber

    ) ],
    {
        'id' => \%id_of,
        'url' => \%url_of,
        'displayUrl' => \%displayUrl_of,
        'devicePreference' => \%devicePreference_of,
        'Ad__Type' => \%Ad__Type_of,
        'headline' => \%headline_of,
        'description' => \%description_of,
        'markupLanguages' => \%markupLanguages_of,
        'mobileCarriers' => \%mobileCarriers_of,
        'businessName' => \%businessName_of,
        'countryCode' => \%countryCode_of,
        'phoneNumber' => \%phoneNumber_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'displayUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'devicePreference' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'Ad__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'headline' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'markupLanguages' => 'Google::Ads::AdWords::v201402::MarkupLanguageType',
        'mobileCarriers' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'businessName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'countryCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'phoneNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'id' => 'id',
        'url' => 'url',
        'displayUrl' => 'displayUrl',
        'devicePreference' => 'devicePreference',
        'Ad__Type' => 'Ad.Type',
        'headline' => 'headline',
        'description' => 'description',
        'markupLanguages' => 'markupLanguages',
        'mobileCarriers' => 'mobileCarriers',
        'businessName' => 'businessName',
        'countryCode' => 'countryCode',
        'phoneNumber' => 'phoneNumber',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201402::MobileAd

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
MobileAd from the namespace https://adwords.google.com/api/adwords/cm/v201402.

Represents a mobile ad. <p> A mobile ad can contain a click-to-call phone number, a link to a website, or both. You specify which features you want by setting certain fields, as shown in the following table. For example, to create a click-to-call mobile ad, set the fields in the <b>Click-to-call</b> column. A hyphen indicates that you should not set the corresponding field. </p> <p> For more information, see <a href="//support.google.com/adwords/bin/answer.py?answer=2472720"> Create a mobile ad</a>. </p> <table summary="" style="clear: none"> <tr> <th scope="col"> Click-to-call </th> <th scope="col"> Website </th> <th scope="col"> Both </th></tr> <tr> <td> headline <br /> description <br /> mobileCarriers <br /> phoneNumber <br /> countryCode <br /> businessName <br /> - <br /> - <br /> - <br /> </td> <td> headline <br /> description <br /> mobileCarriers <br /> - <br /> - <br /> - <br /> displayUrl <br /> destinationUrl <br /> markupLanguages <br /> </td> <td> headline <br /> description <br /> mobileCarriers <br /> phoneNumber <br /> countryCode <br /> businessName <br /> displayUrl <br /> destinationUrl <br /> markupLanguages <br /> </td></tr> </table> <span class="constraint AdxEnabled">This is disabled for AdX when it is contained within Operators: ADD, SET.</span> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * headline


=item * description


=item * markupLanguages


=item * mobileCarriers


=item * businessName


=item * countryCode


=item * phoneNumber




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

