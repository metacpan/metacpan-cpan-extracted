package Google::Ads::AdWords::v201802::AdGroupAdService::AdGroupAdServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201802::TypeMaps::AdGroupAdService
    if not Google::Ads::AdWords::v201802::TypeMaps::AdGroupAdService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201802/AdGroupAdService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201802::TypeMaps::AdGroupAdService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201802::AdGroupAdService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201802::AdGroupAdService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201802::AdGroupAdService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201802::AdGroupAdService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutateLabel {
    my ($self, $body, $header) = @_;
    die "mutateLabel must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutateLabel',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201802::AdGroupAdService::mutateLabel )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201802::AdGroupAdService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201802::AdGroupAdService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201802::AdGroupAdService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201802::AdGroupAdService::AdGroupAdServiceInterfacePort - SOAP Interface for the AdGroupAdService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201802::AdGroupAdService::AdGroupAdServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201802::AdGroupAdService::AdGroupAdServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->mutateLabel();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the AdGroupAdService web service
located at https://adwords.google.com/api/adwords/cm/v201802/AdGroupAdService.

=head1 SERVICE AdGroupAdService



=head2 Port AdGroupAdServiceInterfacePort



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

Returns a list of AdGroupAds. AdGroupAds that had been removed are not returned by default. @param serviceSelector The selector specifying the {@link AdGroupAd}s to return. @return The page containing the AdGroupAds that meet the criteria specified by the selector. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201802::AdGroupAdService::getResponse|Google::Ads::AdWords::v201802::AdGroupAdService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201802::Selector
  },,
 );

=head3 mutate

Applies the list of mutate operations (ie. add, set, remove): <p>Add - Creates a new {@linkplain AdGroupAd ad group ad}. The {@code adGroupId} must reference an existing ad group. The child {@code Ad} must be sufficiently specified by constructing a concrete ad type (such as {@code TextAd}) and setting its fields accordingly.</p> <p>Set - Updates an ad group ad. Except for {@code status}, ad group ad fields are not mutable. Status updates are straightforward - the status of the ad group ad is updated as specified. If any other field has changed, it will be ignored. If you want to change any of the fields other than status, you must make a new ad and then remove the old one.</p> <p>Remove - Removes the link between the specified AdGroup and Ad.</p> @param operations The operations to apply. @return A list of AdGroupAds where each entry in the list is the result of applying the operation in the input list with the same index. For an add/set operation, the return AdGroupAd will be what is saved to the db. In the case of the remove operation, the return AdGroupAd will simply be an AdGroupAd containing an Ad with the id set to the Ad being removed from the AdGroup. 

Returns a L<Google::Ads::AdWords::v201802::AdGroupAdService::mutateResponse|Google::Ads::AdWords::v201802::AdGroupAdService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201802::AdGroupAdOperation
  },,
 );

=head3 mutateLabel

Adds labels to the AdGroupAd or removes labels from the AdGroupAd. <p>Add - Apply an existing label to an existing {@linkplain AdGroupAd ad group ad}. The {@code adGroupId} and {@code adId} must reference an existing {@linkplain AdGroupAd ad group ad}. The {@code labelId} must reference an existing {@linkplain Label label}. <p>Remove - Removes the link between the specified {@linkplain AdGroupAd ad group ad} and {@linkplain Label label}. @param operations The operations to apply. @return A list of AdGroupAdLabel where each entry in the list is the result of applying the operation in the input list with the same index. For an add operation, the returned AdGroupAdLabel contains the AdGroupId, AdId and the LabelId. In the case of a remove operation, the returned AdGroupAdLabel will only have AdGroupId and AdId. @throws ApiException when there are one or more errors with the request. 

Returns a L<Google::Ads::AdWords::v201802::AdGroupAdService::mutateLabelResponse|Google::Ads::AdWords::v201802::AdGroupAdService::mutateLabelResponse> object.

 $response = $interface->mutateLabel( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201802::AdGroupAdLabelOperation
  },,
 );

=head3 query

Returns a list of AdGroupAds based on the query. @param query The SQL-like AWQL query string. @return A list of AdGroupAds. @throws ApiException if problems occur while parsing the query or fetching AdGroupAds. 

Returns a L<Google::Ads::AdWords::v201802::AdGroupAdService::queryResponse|Google::Ads::AdWords::v201802::AdGroupAdService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Feb 26 21:07:06 2018

=cut
