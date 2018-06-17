package Google::Ads::AdWords::v201806::AccountLabelService::AccountLabelServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::AccountLabelService
    if not Google::Ads::AdWords::v201806::TypeMaps::AccountLabelService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/mcm/v201806/AccountLabelService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::AccountLabelService')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub get {
    my ($self, $body, $header) = @_;
    die "get must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'get',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201806::AccountLabelService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::AccountLabelService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutate {
    my ($self, $body, $header) = @_;
    die "mutate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutate',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201806::AccountLabelService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::AccountLabelService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::AccountLabelService::AccountLabelServiceInterfacePort - SOAP Interface for the AccountLabelService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::AccountLabelService::AccountLabelServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::AccountLabelService::AccountLabelServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the AccountLabelService web service
located at https://adwords.google.com/api/adwords/mcm/v201806/AccountLabelService.

=head1 SERVICE AccountLabelService



=head2 Port AccountLabelServiceInterfacePort



=head1 METHODS

=head2 General methods

=head3 new

Constructor.

All arguments are forwarded to L<SOAP::WSDL::Client|SOAP::WSDL::Client>.

=head2 SOAP Service methods

Method synopsis is displayed with hash refs as parameters.

The commented class names in the method's parameters denote that objects
of the corresponding class can be passed instead of the marked hash ref.

You may pass any combination of objects, hash and list refs to these
methods, as long as you meet the structure.

List items (i.e. multiple occurences) are not displayed in the synopsis.
You may generally pass a list ref of hash refs (or objects) instead of a hash
ref - this may result in invalid XML if used improperly, though. Note that
SOAP::WSDL always expects list references at maximum depth position.

XML attributes are not displayed in this synopsis and cannot be set using
hash refs. See the respective class' documentation for additional information.



=head3 get

Returns a list of labels specified by the selector for the authenticated user. @param selector filters the list of labels to return @return response containing lists of labels that meet all the criteria of the selector @throws ApiException if a problem occurs fetching the information requested 

Returns a L<Google::Ads::AdWords::v201806::AccountLabelService::getResponse|Google::Ads::AdWords::v201806::AccountLabelService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 mutate

Possible actions: <ul> <li> Create a new label - create a new {@link Label} and call mutate with ADD operator <li> Edit the label name - set the appropriate fields in your {@linkplain Label} and call mutate with the SET operator. Null fields will be interpreted to mean "no change" <li> Delete the label - call mutate with REMOVE operator </ul> @param operations list of unique operations to be executed in a single transaction, in the order specified. @return the mutated labels, in the same order that they were in as the parameter @throws ApiException if problems occurs while modifying label information 

Returns a L<Google::Ads::AdWords::v201806::AccountLabelService::mutateResponse|Google::Ads::AdWords::v201806::AccountLabelService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::AccountLabelOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Jun  6 17:29:13 2018

=cut
