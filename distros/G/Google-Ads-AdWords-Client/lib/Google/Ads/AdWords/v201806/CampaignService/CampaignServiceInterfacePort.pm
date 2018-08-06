package Google::Ads::AdWords::v201806::CampaignService::CampaignServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::CampaignService
    if not Google::Ads::AdWords::v201806::TypeMaps::CampaignService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201806/CampaignService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::CampaignService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignService::mutateLabel )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::CampaignService::CampaignServiceInterfacePort - SOAP Interface for the CampaignService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::CampaignService::CampaignServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::CampaignService::CampaignServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->mutateLabel();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the CampaignService web service
located at https://adwords.google.com/api/adwords/cm/v201806/CampaignService.

=head1 SERVICE CampaignService



=head2 Port CampaignServiceInterfacePort



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

Returns the list of campaigns that meet the selector criteria. @param serviceSelector the selector specifying the {@link Campaign}s to return. @return A list of campaigns. @throws ApiException if problems occurred while fetching campaign information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignService::getResponse|Google::Ads::AdWords::v201806::CampaignService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 mutate

Adds, updates, or removes campaigns. <p class="note"><b>Note:</b> {@link CampaignOperation} does not support the <code>REMOVE</code> operator. To remove a campaign, set its {@link Campaign#status status} to {@code REMOVED}.</p> @param operations A list of unique operations. The same campaign cannot be specified in more than one operation. @return The list of updated campaigns, returned in the same order as the <code>operations</code> array. @throws ApiException if problems occurred while updating campaign information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignService::mutateResponse|Google::Ads::AdWords::v201806::CampaignService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::CampaignOperation
  },,
 );

=head3 mutateLabel

Adds labels to the {@linkplain Campaign campaign} or removes {@linkplain Label label}s from the {@linkplain Campaign campaign}. <p>Add - Apply an existing label to an existing {@linkplain Campaign campaign}. The {@code campaignId} must reference an existing {@linkplain Campaign}. The {@code labelId} must reference an existing {@linkplain Label label}. <p>Remove - Removes the link between the specified {@linkplain Campaign campaign} and {@linkplain Label label}. @param operations the operations to apply. @return a list of {@linkplain CampaignLabel}s where each entry in the list is the result of applying the operation in the input list with the same index. For an add operation, the returned CampaignLabel contains the CampaignId and the LabelId. In the case of a remove operation, the returned CampaignLabel will only have CampaignId. @throws ApiException when there are one or more errors with the request. 

Returns a L<Google::Ads::AdWords::v201806::CampaignService::mutateLabelResponse|Google::Ads::AdWords::v201806::CampaignService::mutateLabelResponse> object.

 $response = $interface->mutateLabel( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::CampaignLabelOperation
  },,
 );

=head3 query

Returns the list of campaigns that match the query. @param query The SQL-like AWQL query string. @return A list of campaigns. @throws ApiException if problems occur while parsing the query or fetching campaign information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignService::queryResponse|Google::Ads::AdWords::v201806::CampaignService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Jul 19 11:22:44 2018

=cut
