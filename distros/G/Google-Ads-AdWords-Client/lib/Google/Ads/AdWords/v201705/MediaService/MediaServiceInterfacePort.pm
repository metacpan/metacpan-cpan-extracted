package Google::Ads::AdWords::v201705::MediaService::MediaServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201705::TypeMaps::MediaService
    if not Google::Ads::AdWords::v201705::TypeMaps::MediaService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201705/MediaService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201705::TypeMaps::MediaService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201705::MediaService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201705::MediaService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201705::MediaService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201705::MediaService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub upload {
    my ($self, $body, $header) = @_;
    die "upload must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'upload',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201705::MediaService::upload )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201705::MediaService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201705::MediaService::MediaServiceInterfacePort - SOAP Interface for the MediaService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201705::MediaService::MediaServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201705::MediaService::MediaServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->query();
 $response = $interface->upload();



=head1 DESCRIPTION

SOAP Interface for the MediaService web service
located at https://adwords.google.com/api/adwords/cm/v201705/MediaService.

=head1 SERVICE MediaService



=head2 Port MediaServiceInterfacePort



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

Returns a list of media that meet the criteria specified by the selector. <p class="note"><b>Note:</b> {@code MediaService} will not return any {@link ImageAd} image files.</p> @param serviceSelector Selects which media objects to return. @return A list of {@code Media} objects. 

Returns a L<Google::Ads::AdWords::v201705::MediaService::getResponse|Google::Ads::AdWords::v201705::MediaService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201705::Selector
  },,
 );

=head3 query

Returns the list of {@link Media} objects that match the query. @param query The SQL-like AWQL query string @returns A list of {@code Media} objects. @throws ApiException when the query is invalid or there are errors processing the request. 

Returns a L<Google::Ads::AdWords::v201705::MediaService::queryResponse|Google::Ads::AdWords::v201705::MediaService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );

=head3 upload

Uploads new media. Currently, you can upload {@link Image} files and {@link MediaBundle}s. @param media A list of {@code Media} objects, each containing the data to be uploaded. @return A list of uploaded media in the same order as the argument list. 

Returns a L<Google::Ads::AdWords::v201705::MediaService::uploadResponse|Google::Ads::AdWords::v201705::MediaService::uploadResponse> object.

 $response = $interface->upload( {
    media =>  $a_reference_to, # see Google::Ads::AdWords::v201705::Media
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed May 31 08:54:03 2017

=cut
