
package Google::Ads::AdWords::v201309::CustomerService::ApiExceptionFault;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'https://adwords.google.com/api/adwords/mcm/v201309' }

__PACKAGE__->__set_name('ApiExceptionFault');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();
use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    Google::Ads::AdWords::v201309::ApiException
);

}

1;


=pod

=head1 NAME

Google::Ads::AdWords::v201309::CustomerService::ApiExceptionFault

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
ApiExceptionFault from the namespace https://adwords.google.com/api/adwords/mcm/v201309.

A fault element of type ApiException. 





=head1 METHODS

=head2 new

 my $element = Google::Ads::AdWords::v201309::CustomerService::ApiExceptionFault->new($data);

Constructor. The following data structure may be passed to new():

 $a_reference_to, # see Google::Ads::AdWords::v201309::ApiException

=head1 AUTHOR

Generated by SOAP::WSDL

=cut

