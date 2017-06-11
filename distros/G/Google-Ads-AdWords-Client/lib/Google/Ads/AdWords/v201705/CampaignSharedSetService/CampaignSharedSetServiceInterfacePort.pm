package Google::Ads::AdWords::v201705::CampaignSharedSetService::CampaignSharedSetServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201705::TypeMaps::CampaignSharedSetService
    if not Google::Ads::AdWords::v201705::TypeMaps::CampaignSharedSetService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201705/CampaignSharedSetService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201705::TypeMaps::CampaignSharedSetService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201705::CampaignSharedSetService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201705::CampaignSharedSetService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201705::CampaignSharedSetService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201705::CampaignSharedSetService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201705::CampaignSharedSetService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201705::CampaignSharedSetService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201705::CampaignSharedSetService::CampaignSharedSetServiceInterfacePort - SOAP Interface for the CampaignSharedSetService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201705::CampaignSharedSetService::CampaignSharedSetServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201705::CampaignSharedSetService::CampaignSharedSetServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the CampaignSharedSetService web service
located at https://adwords.google.com/api/adwords/cm/v201705/CampaignSharedSetService.

=head1 SERVICE CampaignSharedSetService



=head2 Port CampaignSharedSetServiceInterfacePort



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

Returns a list of CampaignSharedSets based on the given selector. @param selector the selector specifying the query @return a list of CampaignSharedSet entities that meet the criterion specified by the selector @throws ApiException 

Returns a L<Google::Ads::AdWords::v201705::CampaignSharedSetService::getResponse|Google::Ads::AdWords::v201705::CampaignSharedSetService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201705::Selector
  },,
 );

=head3 mutate

Applies the list of mutate operations. @param operations the operations to apply @return the modified list of CampaignSharedSet associations @throws ApiException 

Returns a L<Google::Ads::AdWords::v201705::CampaignSharedSetService::mutateResponse|Google::Ads::AdWords::v201705::CampaignSharedSetService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201705::CampaignSharedSetOperation
  },,
 );

=head3 query

Returns the list of CampaignSharedSets that match the query. @param query The SQL-like AWQL query string @returns A list of CampaignSharedSets @throws ApiException when the query is invalid or there are errors processing the request. 

Returns a L<Google::Ads::AdWords::v201705::CampaignSharedSetService::queryResponse|Google::Ads::AdWords::v201705::CampaignSharedSetService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed May 31 08:53:05 2017

=cut
