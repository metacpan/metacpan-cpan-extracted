package Google::Ads::AdWords::v201609::CampaignExtensionSettingService::CampaignExtensionSettingServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201609::TypeMaps::CampaignExtensionSettingService
    if not Google::Ads::AdWords::v201609::TypeMaps::CampaignExtensionSettingService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201609/CampaignExtensionSettingService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201609::TypeMaps::CampaignExtensionSettingService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201609::CampaignExtensionSettingService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::CampaignExtensionSettingService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201609::CampaignExtensionSettingService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::CampaignExtensionSettingService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201609::CampaignExtensionSettingService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::CampaignExtensionSettingService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201609::CampaignExtensionSettingService::CampaignExtensionSettingServiceInterfacePort - SOAP Interface for the CampaignExtensionSettingService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201609::CampaignExtensionSettingService::CampaignExtensionSettingServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201609::CampaignExtensionSettingService::CampaignExtensionSettingServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the CampaignExtensionSettingService web service
located at https://adwords.google.com/api/adwords/cm/v201609/CampaignExtensionSettingService.

=head1 SERVICE CampaignExtensionSettingService



=head2 Port CampaignExtensionSettingServiceInterfacePort



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

Returns a list of CampaignExtensionSettings that meet the selector criteria. @param selector Determines which CampaignExtensionSettings to return. If empty, all CampaignExtensionSettings are returned. @return The list of CampaignExtensionSettings specified by the selector. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201609::CampaignExtensionSettingService::getResponse|Google::Ads::AdWords::v201609::CampaignExtensionSettingService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201609::Selector
  },,
 );

=head3 mutate

Applies the list of mutate operations (add, remove, and set). <p> Beginning in v201509, add and set operations are treated identically. Performing an add operation on a campaign with an existing ExtensionSetting will cause the operation to be treated like a set operation. Performing a set operation on a campaign with no ExtensionSetting will cause the operation to be treated like an add operation. @param operations The operations to apply. The same {@link CampaignExtensionSetting} cannot be specified in more than one operation. @return The changed {@link CampaignExtensionSetting}s. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201609::CampaignExtensionSettingService::mutateResponse|Google::Ads::AdWords::v201609::CampaignExtensionSettingService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201609::CampaignExtensionSettingOperation
  },,
 );

=head3 query

Returns a list of CampaignExtensionSettings that match the query. @param query The SQL-like AWQL query string. @return The list of CampaignExtensionSettings specified by the query. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201609::CampaignExtensionSettingService::queryResponse|Google::Ads::AdWords::v201609::CampaignExtensionSettingService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu May 25 10:00:12 2017

=cut
