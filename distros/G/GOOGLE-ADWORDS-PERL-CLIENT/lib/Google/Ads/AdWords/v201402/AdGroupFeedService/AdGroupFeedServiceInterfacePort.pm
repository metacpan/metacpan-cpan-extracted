package Google::Ads::AdWords::v201402::AdGroupFeedService::AdGroupFeedServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201402::TypeMaps::AdGroupFeedService
    if not Google::Ads::AdWords::v201402::TypeMaps::AdGroupFeedService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201402/AdGroupFeedService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201402::TypeMaps::AdGroupFeedService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdGroupFeedService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdGroupFeedService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdGroupFeedService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdGroupFeedService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201402::AdGroupFeedService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201402::AdGroupFeedService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201402::AdGroupFeedService::AdGroupFeedServiceInterfacePort - SOAP Interface for the AdGroupFeedService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201402::AdGroupFeedService::AdGroupFeedServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201402::AdGroupFeedService::AdGroupFeedServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the AdGroupFeedService web service
located at https://adwords.google.com/api/adwords/cm/v201402/AdGroupFeedService.

=head1 SERVICE AdGroupFeedService



=head2 Port AdGroupFeedServiceInterfacePort



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

Returns a list of AdGroupFeeds that meet the selector criteria. @param selector Determines which AdGroupFeeds to return. If empty all adgroup feeds are returned. @return The list of AdgroupFeeds. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201402::AdGroupFeedService::getResponse|Google::Ads::AdWords::v201402::AdGroupFeedService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201402::Selector
  },,
 );

=head3 mutate

Adds, updates or removes AdGroupFeeds. @param operations The operations to apply. @return The resulting Feeds. @throws ApiException Indicates a problem with the request. 

Returns a L<Google::Ads::AdWords::v201402::AdGroupFeedService::mutateResponse|Google::Ads::AdWords::v201402::AdGroupFeedService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201402::AdGroupFeedOperation
  },,
 );

=head3 query

Returns the list of AdGroupFeeds that match the query. @param query The SQL-like AWQL query string. @returns A list of AdGroupFeed. @throws ApiException if problems occur while parsing the query or fetching AdGroupFeed. 

Returns a L<Google::Ads::AdWords::v201402::AdGroupFeedService::queryResponse|Google::Ads::AdWords::v201402::AdGroupFeedService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Feb 26 12:38:20 2014

=cut
