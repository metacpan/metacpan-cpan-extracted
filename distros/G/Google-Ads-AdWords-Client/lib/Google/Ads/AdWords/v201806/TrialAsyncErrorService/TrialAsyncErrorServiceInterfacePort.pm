package Google::Ads::AdWords::v201806::TrialAsyncErrorService::TrialAsyncErrorServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::TrialAsyncErrorService
    if not Google::Ads::AdWords::v201806::TypeMaps::TrialAsyncErrorService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201806/TrialAsyncErrorService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::TrialAsyncErrorService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::TrialAsyncErrorService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::TrialAsyncErrorService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub query {
    my ($self, $body, $header) = @_;
    die "query must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'query',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201806::TrialAsyncErrorService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::TrialAsyncErrorService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::TrialAsyncErrorService::TrialAsyncErrorServiceInterfacePort - SOAP Interface for the TrialAsyncErrorService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::TrialAsyncErrorService::TrialAsyncErrorServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::TrialAsyncErrorService::TrialAsyncErrorServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the TrialAsyncErrorService web service
located at https://adwords.google.com/api/adwords/cm/v201806/TrialAsyncErrorService.

=head1 SERVICE TrialAsyncErrorService



=head2 Port TrialAsyncErrorServiceInterfacePort



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

Returns a TrialAsyncErrorPage that contains a list of TrialAsyncErrors matching the selector. @throws {#link com.google.ads.api.services.common.error.ApiException} if problems occurred while retrieving the results. 

Returns a L<Google::Ads::AdWords::v201806::TrialAsyncErrorService::getResponse|Google::Ads::AdWords::v201806::TrialAsyncErrorService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 query

Returns a TrialAsyncErrorPage that contains a list of TrialAsyncError matching the query. @throws {#link com.google.ads.api.services.common.error.ApiException} if problems occurred while retrieving the results. 

Returns a L<Google::Ads::AdWords::v201806::TrialAsyncErrorService::queryResponse|Google::Ads::AdWords::v201806::TrialAsyncErrorService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Jul 19 11:24:09 2018

=cut
