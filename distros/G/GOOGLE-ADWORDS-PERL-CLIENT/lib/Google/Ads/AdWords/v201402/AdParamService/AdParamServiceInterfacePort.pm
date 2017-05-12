package Google::Ads::AdWords::v201402::AdParamService::AdParamServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201402::TypeMaps::AdParamService
    if not Google::Ads::AdWords::v201402::TypeMaps::AdParamService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201402/AdParamService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201402::TypeMaps::AdParamService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdParamService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdParamService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdParamService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdParamService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201402::AdParamService::AdParamServiceInterfacePort - SOAP Interface for the AdParamService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201402::AdParamService::AdParamServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201402::AdParamService::AdParamServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the AdParamService web service
located at https://adwords.google.com/api/adwords/cm/v201402/AdParamService.

=head1 SERVICE AdParamService



=head2 Port AdParamServiceInterfacePort



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

Returns the ad parameters that match the criteria specified in the selector. @param serviceSelector Specifies which ad parameters to return. @return A list of ad parameters. 

Returns a L<Google::Ads::AdWords::v201402::AdParamService::getResponse|Google::Ads::AdWords::v201402::AdParamService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201402::Selector
  },,
 );

=head3 mutate

Sets and removes ad parameters. <p class="note"><b>Note:</b> {@code ADD} is not supported. Use {@code SET} for new ad parameters.</p> <ul class="nolist"> <li>{@code SET}: Creates or updates an ad parameter, setting the new parameterized value for the given ad group / keyword pair. <li>{@code REMOVE}: Removes an ad parameter. The <code><var>default-value</var> </code> specified in the ad text will be used.</li> </ul> @param operations The operations to perform. @return A list of ad parameters, where each entry in the list is the result of applying the operation in the input list with the same index. For a {@code SET} operation, the returned ad parameter will contain the updated values. For a {@code REMOVE} operation, the returned ad parameter will simply be the ad parameter that was removed. 

Returns a L<Google::Ads::AdWords::v201402::AdParamService::mutateResponse|Google::Ads::AdWords::v201402::AdParamService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201402::AdParamOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Feb 26 12:38:28 2014

=cut
