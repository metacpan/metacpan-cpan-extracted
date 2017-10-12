package Google::Ads::AdWords::v201710::AdCustomizerFeedService::AdCustomizerFeedServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201710::TypeMaps::AdCustomizerFeedService
    if not Google::Ads::AdWords::v201710::TypeMaps::AdCustomizerFeedService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201710/AdCustomizerFeedService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201710::TypeMaps::AdCustomizerFeedService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::AdCustomizerFeedService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::AdCustomizerFeedService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::AdCustomizerFeedService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::AdCustomizerFeedService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201710::AdCustomizerFeedService::AdCustomizerFeedServiceInterfacePort - SOAP Interface for the AdCustomizerFeedService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201710::AdCustomizerFeedService::AdCustomizerFeedServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201710::AdCustomizerFeedService::AdCustomizerFeedServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the AdCustomizerFeedService web service
located at https://adwords.google.com/api/adwords/cm/v201710/AdCustomizerFeedService.

=head1 SERVICE AdCustomizerFeedService



=head2 Port AdCustomizerFeedServiceInterfacePort



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

Returns a list of AdCustomizerFeeds that meet the selector criteria. @param selector Determines which AdCustomizerFeeds to return. If empty, all AdCustomizerFeeds are returned. @return The list of AdCustomizerFeeds. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201710::AdCustomizerFeedService::getResponse|Google::Ads::AdWords::v201710::AdCustomizerFeedService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201710::Selector
  },,
 );

=head3 mutate

Adds, removes, or modifies AdCustomizerFeeds. @param operations The operations to apply. @return The resulting AdCustomizerFeeds. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201710::AdCustomizerFeedService::mutateResponse|Google::Ads::AdWords::v201710::AdCustomizerFeedService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201710::AdCustomizerFeedOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Oct  9 18:26:51 2017

=cut
