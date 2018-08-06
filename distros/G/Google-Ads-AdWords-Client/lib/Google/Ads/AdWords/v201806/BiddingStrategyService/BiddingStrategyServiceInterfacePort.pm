package Google::Ads::AdWords::v201806::BiddingStrategyService::BiddingStrategyServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::BiddingStrategyService
    if not Google::Ads::AdWords::v201806::TypeMaps::BiddingStrategyService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201806/BiddingStrategyService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::BiddingStrategyService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::BiddingStrategyService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::BiddingStrategyService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::BiddingStrategyService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::BiddingStrategyService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::BiddingStrategyService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::BiddingStrategyService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::BiddingStrategyService::BiddingStrategyServiceInterfacePort - SOAP Interface for the BiddingStrategyService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::BiddingStrategyService::BiddingStrategyServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::BiddingStrategyService::BiddingStrategyServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the BiddingStrategyService web service
located at https://adwords.google.com/api/adwords/cm/v201806/BiddingStrategyService.

=head1 SERVICE BiddingStrategyService



=head2 Port BiddingStrategyServiceInterfacePort



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

Returns a list of bidding strategies that match the selector. @return list of bidding strategies specified by the selector. @throws com.google.ads.api.services.common.error.ApiException if problems occurred while retrieving results. 

Returns a L<Google::Ads::AdWords::v201806::BiddingStrategyService::getResponse|Google::Ads::AdWords::v201806::BiddingStrategyService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 mutate

Applies the list of mutate operations. @param operations the operations to apply @return the modified list of BiddingStrategy @throws ApiException 

Returns a L<Google::Ads::AdWords::v201806::BiddingStrategyService::mutateResponse|Google::Ads::AdWords::v201806::BiddingStrategyService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::BiddingStrategyOperation
  },,
 );

=head3 query

Returns a list of bidding strategies that match the query. @param query The SQL-like AWQL query string. @throws ApiException when there are one or more errors with the request. 

Returns a L<Google::Ads::AdWords::v201806::BiddingStrategyService::queryResponse|Google::Ads::AdWords::v201806::BiddingStrategyService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Jul 19 11:22:03 2018

=cut
