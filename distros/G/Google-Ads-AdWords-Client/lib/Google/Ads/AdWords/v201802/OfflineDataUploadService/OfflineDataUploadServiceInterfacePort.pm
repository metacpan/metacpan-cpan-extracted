package Google::Ads::AdWords::v201802::OfflineDataUploadService::OfflineDataUploadServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201802::TypeMaps::OfflineDataUploadService
    if not Google::Ads::AdWords::v201802::TypeMaps::OfflineDataUploadService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/rm/v201802/OfflineDataUploadService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201802::TypeMaps::OfflineDataUploadService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201802::OfflineDataUploadService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201802::OfflineDataUploadService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201802::OfflineDataUploadService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201802::OfflineDataUploadService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201802::OfflineDataUploadService::OfflineDataUploadServiceInterfacePort - SOAP Interface for the OfflineDataUploadService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201802::OfflineDataUploadService::OfflineDataUploadServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201802::OfflineDataUploadService::OfflineDataUploadServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the OfflineDataUploadService web service
located at https://adwords.google.com/api/adwords/rm/v201802/OfflineDataUploadService.

=head1 SERVICE OfflineDataUploadService



=head2 Port OfflineDataUploadServiceInterfacePort



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

Returns a list of OfflineDataUpload objects that match the criteria specified in the selector. <p><b>Note:</b> If an upload fails after processing, reason will be reported in {@link OfflineDataUpload#failureReason}. @throws {@link ApiException} if problems occurred while retrieving results. 

Returns a L<Google::Ads::AdWords::v201802::OfflineDataUploadService::getResponse|Google::Ads::AdWords::v201802::OfflineDataUploadService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201802::Selector
  },,
 );

=head3 mutate

Applies a list of mutate operations (i.e. add, set) to offline data upload: <p>Add - uploads offline data for each entry in operations. Some operations can fail for upload level errors like invalid {@code UploadMetadata}. Check {@code OfflineDataUploadReturnValue} for partial failure list. <p>Set - updates the upload result for each upload. It is for internal use only. <p><b>Note:</b> For AdWords API, one ADD request can have at most 2000 operations. <p><b>Note:</b> Add operation might possibly succeed even with errors in {@code OfflineData}. Data errors are reported in {@link OfflineDataUpload#partialDataErrors} <p><b>Note:</b> Supports only the {@code ADD} operator. {@code SET} operator is internally used only.({@code REMOVE} is not supported). @param operations A list of offline data upload operations. @return The list of offline data upload results in the same order as operations. @throws {@link ApiException} if problems occur. 

Returns a L<Google::Ads::AdWords::v201802::OfflineDataUploadService::mutateResponse|Google::Ads::AdWords::v201802::OfflineDataUploadService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201802::OfflineDataUploadOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Feb 26 21:11:29 2018

=cut
