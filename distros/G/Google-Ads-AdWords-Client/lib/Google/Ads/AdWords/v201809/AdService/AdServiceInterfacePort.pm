package Google::Ads::AdWords::v201809::AdService::AdServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201809::TypeMaps::AdService
    if not Google::Ads::AdWords::v201809::TypeMaps::AdService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201809/AdService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201809::TypeMaps::AdService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201809::AdService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201809::AdService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201809::AdService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201809::AdService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201809::AdService::AdServiceInterfacePort - SOAP Interface for the AdService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201809::AdService::AdServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201809::AdService::AdServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the AdService web service
located at https://adwords.google.com/api/adwords/cm/v201809/AdService.

=head1 SERVICE AdService



=head2 Port AdServiceInterfacePort



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

Returns a list of {@link Ad}s. @param serviceSelector The selector specifying the {@link Ad}s to return. @return The page containing the {@link Ad}s that meet the criteria specified by the selector. @throws {@link ApiException} when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201809::AdService::getResponse|Google::Ads::AdWords::v201809::AdService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201809::Selector
  },,
 );

=head3 mutate

Applies the list of mutate operations. For {@link AdService}, only SET operations are allowed. @param operations The operations to apply. @return A list of {@line Ad}s where each entry in the list is the result of applying the operation in the input list with the same index. The returned {@link Ad}s will be what is saved. 

Returns a L<Google::Ads::AdWords::v201809::AdService::mutateResponse|Google::Ads::AdWords::v201809::AdService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201809::AdOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Sep 20 11:07:02 2018

=cut
