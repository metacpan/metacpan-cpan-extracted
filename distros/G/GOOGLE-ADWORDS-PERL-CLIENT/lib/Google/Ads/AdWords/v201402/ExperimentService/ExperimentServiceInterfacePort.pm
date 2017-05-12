package Google::Ads::AdWords::v201402::ExperimentService::ExperimentServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201402::TypeMaps::ExperimentService
    if not Google::Ads::AdWords::v201402::TypeMaps::ExperimentService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201402/ExperimentService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201402::TypeMaps::ExperimentService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::ExperimentService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::ExperimentService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::ExperimentService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::ExperimentService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201402::ExperimentService::ExperimentServiceInterfacePort - SOAP Interface for the ExperimentService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201402::ExperimentService::ExperimentServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201402::ExperimentService::ExperimentServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the ExperimentService web service
located at https://adwords.google.com/api/adwords/cm/v201402/ExperimentService.

=head1 SERVICE ExperimentService



=head2 Port ExperimentServiceInterfacePort



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

Returns a list of experiments specified by the experiment selector from the customer's account. @param serviceSelector The selector specifying the {@link Experiment}s to return. If selector is empty, all experiments are returned. @return List of experiments meeting all the criteria of each selector. @throws ApiException if problems occurred while fetching experiment information. 

Returns a L<Google::Ads::AdWords::v201402::ExperimentService::getResponse|Google::Ads::AdWords::v201402::ExperimentService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201402::Selector
  },,
 );

=head3 mutate

Mutates (add, update or remove) experiments. <b>Note:</b> To REMOVE use SET and mark status to DELETED. @param operations A list of unique operations. The same experiment cannot be specified in more than one operation. @return The updated experiments. The list of experiments is returned in the same order in which it came in as input. @throws ApiException if problems occurred while updating experiment information. 

Returns a L<Google::Ads::AdWords::v201402::ExperimentService::mutateResponse|Google::Ads::AdWords::v201402::ExperimentService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201402::ExperimentOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Feb 26 12:39:15 2014

=cut
