package Google::Ads::AdWords::v201710::BudgetOrderService::BudgetOrderServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201710::TypeMaps::BudgetOrderService
    if not Google::Ads::AdWords::v201710::TypeMaps::BudgetOrderService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/billing/v201710/BudgetOrderService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201710::TypeMaps::BudgetOrderService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::BudgetOrderService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::BudgetOrderService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getBillingAccounts {
    my ($self, $body, $header) = @_;
    die "getBillingAccounts must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getBillingAccounts',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::BudgetOrderService::getBillingAccounts )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::BudgetOrderService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::BudgetOrderService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::BudgetOrderService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201710::BudgetOrderService::BudgetOrderServiceInterfacePort - SOAP Interface for the BudgetOrderService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201710::BudgetOrderService::BudgetOrderServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201710::BudgetOrderService::BudgetOrderServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->getBillingAccounts();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the BudgetOrderService web service
located at https://adwords.google.com/api/adwords/billing/v201710/BudgetOrderService.

=head1 SERVICE BudgetOrderService



=head2 Port BudgetOrderServiceInterfacePort



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

Gets a list of {@link BudgetOrder}s using the generic selector. @param serviceSelector specifies which BudgetOrder to return. @return A {@link BudgetOrderPage} of BudgetOrders of the client customer. All BudgetOrder fields are returned. Stats are not yet supported. @throws ApiException 

Returns a L<Google::Ads::AdWords::v201710::BudgetOrderService::getResponse|Google::Ads::AdWords::v201710::BudgetOrderService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201710::Selector
  },,
 );

=head3 getBillingAccounts

Returns all the open/active BillingAccounts associated with the current manager. @return A list of {@link BillingAccount}s. @throws ApiException 

Returns a L<Google::Ads::AdWords::v201710::BudgetOrderService::getBillingAccountsResponse|Google::Ads::AdWords::v201710::BudgetOrderService::getBillingAccountsResponse> object.

 $response = $interface->getBillingAccounts( {
  },,
 );

=head3 mutate

Adds, updates, or removes budget orders. Supported operations are: <p><code>ADD</code>: Adds a {@link BudgetOrder} to the billing account specified by the billing account ID.</p> <p><code>SET</code>: Sets the start/end date and amount of the {@link BudgetOrder}.</p> <p><code>REMOVE</code>: Cancels the {@link BudgetOrder} (status change).</p> <p class="warning"><b>Warning:</b> The <code>BudgetOrderService</code> is limited to one operation per mutate request. Any attempt to make more than one operation will result in an <code>ApiException</code>.</p> <p class="note"><b>Note:</b> This action is available only on a whitelist basis.</p> @param operations A list of operations, <b>however currently we only support one operation per mutate call</b>. @return BudgetOrders affected by the mutate operation. @throws ApiException 

Returns a L<Google::Ads::AdWords::v201710::BudgetOrderService::mutateResponse|Google::Ads::AdWords::v201710::BudgetOrderService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201710::BudgetOrderOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Oct  9 18:31:00 2017

=cut
