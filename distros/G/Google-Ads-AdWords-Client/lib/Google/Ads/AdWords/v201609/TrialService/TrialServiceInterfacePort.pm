package Google::Ads::AdWords::v201609::TrialService::TrialServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201609::TypeMaps::TrialService
    if not Google::Ads::AdWords::v201609::TypeMaps::TrialService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201609/TrialService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201609::TypeMaps::TrialService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201609::TrialService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::TrialService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201609::TrialService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::TrialService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201609::TrialService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::TrialService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201609::TrialService::TrialServiceInterfacePort - SOAP Interface for the TrialService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201609::TrialService::TrialServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201609::TrialService::TrialServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the TrialService web service
located at https://adwords.google.com/api/adwords/cm/v201609/TrialService.

=head1 SERVICE TrialService



=head2 Port TrialServiceInterfacePort



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

Loads a TrialPage containing a list of {@link Trial} objects matching the selector. @param selector defines which subset of all available trials to return, the sort order, and which fields to include @return Returns a page of matching trial objects. @throws com.google.ads.api.services.common.error.ApiException if errors occurred while retrieving the results. 

Returns a L<Google::Ads::AdWords::v201609::TrialService::getResponse|Google::Ads::AdWords::v201609::TrialService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201609::Selector
  },,
 );

=head3 mutate

Creates new trials, updates properties and controls the life cycle of existing trials. See {@link TrialService} for details on the trial life cycle. @return Returns the list of updated Trials, in the same order as the {@code operations} list. @throws com.google.ads.api.services.common.error.ApiException if errors occurred while processing the request. 

Returns a L<Google::Ads::AdWords::v201609::TrialService::mutateResponse|Google::Ads::AdWords::v201609::TrialService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201609::TrialOperation
  },,
 );

=head3 query

Loads a TrialPage containing a list of {@link Trial} objects matching the query. @param query defines which subset of all available trials to return, the sort order, and which fields to include @return Returns a page of matching trial objects. @throws com.google.ads.api.services.common.error.ApiException if errors occurred while retrieving the results. 

Returns a L<Google::Ads::AdWords::v201609::TrialService::queryResponse|Google::Ads::AdWords::v201609::TrialService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu May 25 10:01:35 2017

=cut
