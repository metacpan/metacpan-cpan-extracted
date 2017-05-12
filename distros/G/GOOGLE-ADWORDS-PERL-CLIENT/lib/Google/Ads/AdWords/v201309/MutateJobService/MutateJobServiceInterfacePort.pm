package Google::Ads::AdWords::v201309::MutateJobService::MutateJobServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201309::TypeMaps::MutateJobService
    if not Google::Ads::AdWords::v201309::TypeMaps::MutateJobService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201309/MutateJobService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201309::TypeMaps::MutateJobService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201309::MutateJobService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201309::MutateJobService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getResult {
    my ($self, $body, $header) = @_;
    die "getResult must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getResult',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201309::MutateJobService::getResult )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201309::MutateJobService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201309::MutateJobService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201309::MutateJobService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201309::MutateJobService::MutateJobServiceInterfacePort - SOAP Interface for the MutateJobService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201309::MutateJobService::MutateJobServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201309::MutateJobService::MutateJobServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->getResult();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the MutateJobService web service
located at https://adwords.google.com/api/adwords/cm/v201309/MutateJobService.

=head1 SERVICE MutateJobService



=head2 Port MutateJobServiceInterfacePort



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

Query the status of existing jobs, both simple and bulk API. <p>Use a {@link JobSelector} to query and return a list which may contain both {@link BulkMutateJob} and/or {@link SimpleMutateJob}.</p> 

Returns a L<Google::Ads::AdWords::v201309::MutateJobService::getResponse|Google::Ads::AdWords::v201309::MutateJobService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201309::JobSelector
  },,
 );

=head3 getResult

Query mutation results, of a {@code COMPLETED} job. <p>Use a {@link JobSelector} to query and return either a {@link BulkMutateResult} or a {@link SimpleMutateResult}. Submit only one job ID at a time.</p> 

Returns a L<Google::Ads::AdWords::v201309::MutateJobService::getResultResponse|Google::Ads::AdWords::v201309::MutateJobService::getResultResponse> object.

 $response = $interface->getResult( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201309::JobSelector
  },,
 );

=head3 mutate

Simplified way of submitting a mutation job. The provided list of operations, if valid, will create a new job with a unique id, which will be returned. This id can later be used in invocations of {@link #get} and {@link #getResult}. Policy can optionally be specified. <p>When this method returns with success, the job will be in {@code PROCESSING} or {@code PENDING} state and no further action is needed for the job to get executed.</p> 

Returns a L<Google::Ads::AdWords::v201309::MutateJobService::mutateResponse|Google::Ads::AdWords::v201309::MutateJobService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201309::Operation
    policy =>  $a_reference_to, # see Google::Ads::AdWords::v201309::BulkMutateJobPolicy
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Fri Oct  4 12:05:23 2013

=cut
