package Google::Ads::AdWords::v201806::CustomAffinityService::CustomAffinityServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::CustomAffinityService
    if not Google::Ads::AdWords::v201806::TypeMaps::CustomAffinityService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/rm/v201806/CustomAffinityService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::CustomAffinityService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CustomAffinityService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CustomAffinityService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CustomAffinityService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CustomAffinityService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutateToken {
    my ($self, $body, $header) = @_;
    die "mutateToken must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutateToken',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201806::CustomAffinityService::mutateToken )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CustomAffinityService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CustomAffinityService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CustomAffinityService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::CustomAffinityService::CustomAffinityServiceInterfacePort - SOAP Interface for the CustomAffinityService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::CustomAffinityService::CustomAffinityServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::CustomAffinityService::CustomAffinityServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->mutateToken();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the CustomAffinityService web service
located at https://adwords.google.com/api/adwords/rm/v201806/CustomAffinityService.

=head1 SERVICE CustomAffinityService



=head2 Port CustomAffinityServiceInterfacePort



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

Provides the ability to get one or more custom affinity audience with the ability to filter based various criteria. @param serviceSelector a selector describing the subset of custom affinity audience for this customer. @return A page of custom affinity audience as described by the selector. 

Returns a L<Google::Ads::AdWords::v201806::CustomAffinityService::getResponse|Google::Ads::AdWords::v201806::CustomAffinityService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 mutate

Applies a list of mutate operations (i.e. add, set) to custom affinity audience: <p> Add - creates a custom affinity audience Set - updates a custom affinity audience <p> Notice that custom affinity tokens are not managed by this method. They are created/deleted by <code>mutateToken</code> method. But when a new custom affinity audience is added, its tokens are also added. @param operations the operations to apply @return a list of CustomAffinity objects 

Returns a L<Google::Ads::AdWords::v201806::CustomAffinityService::mutateResponse|Google::Ads::AdWords::v201806::CustomAffinityService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::CustomAffinityOperation
  },,
 );

=head3 mutateToken

Applies a list of mutate operations (i.e. add, remove) to custom affinity tokens: <p> Add - creates a custom affinity token Set - set operation for custom affinity token is not supported Remove - deletes a custom affinity token @param operations the operations to apply @return a list of CustomAffinityToken objects 

Returns a L<Google::Ads::AdWords::v201806::CustomAffinityService::mutateTokenResponse|Google::Ads::AdWords::v201806::CustomAffinityService::mutateTokenResponse> object.

 $response = $interface->mutateToken( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::CustomAffinityTokenOperation
  },,
 );

=head3 query

Returns the list of CustomAffinity that match the query. @param query The SQL-like AWQL query string @return A list of CustomAffinity @throws ApiException when the query is invalid or there are errors processing the request. 

Returns a L<Google::Ads::AdWords::v201806::CustomAffinityService::queryResponse|Google::Ads::AdWords::v201806::CustomAffinityService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Jul 19 11:19:45 2018

=cut
