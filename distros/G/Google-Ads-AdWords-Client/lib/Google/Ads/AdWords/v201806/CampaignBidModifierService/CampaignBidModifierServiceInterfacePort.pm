package Google::Ads::AdWords::v201806::CampaignBidModifierService::CampaignBidModifierServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::CampaignBidModifierService
    if not Google::Ads::AdWords::v201806::TypeMaps::CampaignBidModifierService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201806/CampaignBidModifierService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::CampaignBidModifierService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignBidModifierService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignBidModifierService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignBidModifierService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignBidModifierService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignBidModifierService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignBidModifierService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::CampaignBidModifierService::CampaignBidModifierServiceInterfacePort - SOAP Interface for the CampaignBidModifierService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::CampaignBidModifierService::CampaignBidModifierServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::CampaignBidModifierService::CampaignBidModifierServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the CampaignBidModifierService web service
located at https://adwords.google.com/api/adwords/cm/v201806/CampaignBidModifierService.

=head1 SERVICE CampaignBidModifierService



=head2 Port CampaignBidModifierServiceInterfacePort



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

Returns the list of campaign bid modifiers that meet the selector criteria. @param selector specifying the {@link CampaignBidModifier}s to return. @return A list of campaign bid modifiers. @throws ApiException if problems occurred while fetching campaign bid modifier information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignBidModifierService::getResponse|Google::Ads::AdWords::v201806::CampaignBidModifierService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 mutate

Adds, updates, or deletes campaign bid modifiers. @param operations A list of unique operations. @return The list of updated campaign bid modifiers, returned in the same order as the <code> operations</code> array. @throws ApiException if problems occurred while updating campaign bid modifiers information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignBidModifierService::mutateResponse|Google::Ads::AdWords::v201806::CampaignBidModifierService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::CampaignBidModifierOperation
  },,
 );

=head3 query

Returns a list of {@link CampaignBidModifier}s that match the query. @param query The SQL-like AWQL query string. @throws ApiException when there are one or more errors with the request. 

Returns a L<Google::Ads::AdWords::v201806::CampaignBidModifierService::queryResponse|Google::Ads::AdWords::v201806::CampaignBidModifierService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Jul 19 11:22:09 2018

=cut
