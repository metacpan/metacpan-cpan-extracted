package Google::Ads::AdWords::v201702::BatchJobService::BatchJobServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201702::TypeMaps::BatchJobService
    if not Google::Ads::AdWords::v201702::TypeMaps::BatchJobService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201702/BatchJobService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201702::TypeMaps::BatchJobService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201702::BatchJobService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::BatchJobService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201702::BatchJobService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::BatchJobService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201702::BatchJobService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::BatchJobService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201702::BatchJobService::BatchJobServiceInterfacePort - SOAP Interface for the BatchJobService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201702::BatchJobService::BatchJobServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201702::BatchJobService::BatchJobServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the BatchJobService web service
located at https://adwords.google.com/api/adwords/cm/v201702/BatchJobService.

=head1 SERVICE BatchJobService



=head2 Port BatchJobServiceInterfacePort



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

Query the status of existing {@code BatchJob}s. @param selector The selector specifying the {@code BatchJob}s to return. @return The list of selected jobs. @throws ApiException 

Returns a L<Google::Ads::AdWords::v201702::BatchJobService::getResponse|Google::Ads::AdWords::v201702::BatchJobService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201702::Selector
  },,
 );

=head3 mutate

Creates or updates a {@code BatchJob}. <p class="note"><b>Note:</b> {@link BatchJobOperation} does not support the {@code REMOVE} operator. It is not necessary to remove BatchJobs. @param operations A list of operations. @return The list of created or updated jobs. @throws ApiException 

Returns a L<Google::Ads::AdWords::v201702::BatchJobService::mutateResponse|Google::Ads::AdWords::v201702::BatchJobService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201702::BatchJobOperation
  },,
 );

=head3 query

Returns the list of {@code BatchJob}s that match the query. @param query The SQL-like AWQL query string. @return The list of selected jobs. @throws ApiException if problems occur while parsing the query or fetching batchjob information. 

Returns a L<Google::Ads::AdWords::v201702::BatchJobService::queryResponse|Google::Ads::AdWords::v201702::BatchJobService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Feb 27 23:12:55 2017

=cut
