package Google::Ads::AdWords::v201402::AdGroupService::AdGroupServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201402::TypeMaps::AdGroupService
    if not Google::Ads::AdWords::v201402::TypeMaps::AdGroupService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201402/AdGroupService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201402::TypeMaps::AdGroupService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdGroupService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdGroupService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdGroupService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdGroupService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdGroupService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdGroupService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201402::AdGroupService::AdGroupServiceInterfacePort - SOAP Interface for the AdGroupService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201402::AdGroupService::AdGroupServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201402::AdGroupService::AdGroupServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the AdGroupService web service
located at https://adwords.google.com/api/adwords/cm/v201402/AdGroupService.

=head1 SERVICE AdGroupService



=head2 Port AdGroupServiceInterfacePort



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

Returns a list of all the ad groups specified by the selector from the target customer's account. @param serviceSelector The selector specifying the {@link AdGroup}s to return. @return List of adgroups identified by the selector. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201402::AdGroupService::getResponse|Google::Ads::AdWords::v201402::AdGroupService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201402::Selector
  },,
 );

=head3 mutate

Adds, updates, or deletes ad groups. <p class="note"><b>Note:</b> {@link AdGroupOperation} does not support the {@code REMOVE} operator. To delete an ad group, set its {@link AdGroup#status status} to {@code DELETED}.</p> @param operations List of unique operations. The same ad group cannot be specified in more than one operation. @return The updated adgroups. 

Returns a L<Google::Ads::AdWords::v201402::AdGroupService::mutateResponse|Google::Ads::AdWords::v201402::AdGroupService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201402::AdGroupOperation
  },,
 );

=head3 query

Returns the list of ad groups that match the query. @param query The SQL-like AWQL query string @return A list of adgroups @throws ApiException 

Returns a L<Google::Ads::AdWords::v201402::AdGroupService::queryResponse|Google::Ads::AdWords::v201402::AdGroupService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Feb 26 12:38:26 2014

=cut
