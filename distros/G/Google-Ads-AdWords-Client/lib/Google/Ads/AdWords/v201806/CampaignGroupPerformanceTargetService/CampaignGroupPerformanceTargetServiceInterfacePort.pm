package Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::CampaignGroupPerformanceTargetServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201806::TypeMaps::CampaignGroupPerformanceTargetService
    if not Google::Ads::AdWords::v201806::TypeMaps::CampaignGroupPerformanceTargetService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201806/CampaignGroupPerformanceTargetService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201806::TypeMaps::CampaignGroupPerformanceTargetService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::CampaignGroupPerformanceTargetServiceInterfacePort - SOAP Interface for the CampaignGroupPerformanceTargetService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::CampaignGroupPerformanceTargetServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::CampaignGroupPerformanceTargetServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the CampaignGroupPerformanceTargetService web service
located at https://adwords.google.com/api/adwords/cm/v201806/CampaignGroupPerformanceTargetService.

=head1 SERVICE CampaignGroupPerformanceTargetService



=head2 Port CampaignGroupPerformanceTargetServiceInterfacePort



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

Returns the list of campaign group performance targets that meet the selector criteria. @param selector specifying the {@link CampaignGroupPerformanceTarget}s to return. @return A list of campaign group performance targets. @throws ApiException if problems occurred while fetching campaign group performance target information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::getResponse|Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201806::Selector
  },,
 );

=head3 mutate

Adds, updates, or deletes campaign group performance targets. @param operations A list of unique operations. @return The list of updated campaign groups performance targets, returned in the same order as the <code>operations</code> array. @throws ApiException if problems occurred while updating campaign group performance target information. 

Returns a L<Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::mutateResponse|Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201806::CampaignGroupPerformanceTargetOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu Jul 19 11:22:37 2018

=cut
