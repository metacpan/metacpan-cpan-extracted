package Google::Ads::AdWords::v201702::ManagedCustomerService::ManagedCustomerServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201702::TypeMaps::ManagedCustomerService
    if not Google::Ads::AdWords::v201702::TypeMaps::ManagedCustomerService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/mcm/v201702/ManagedCustomerService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201702::TypeMaps::ManagedCustomerService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getPendingInvitations {
    my ($self, $body, $header) = @_;
    die "getPendingInvitations must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getPendingInvitations',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::getPendingInvitations )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::mutateLabel )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutateLink {
    my ($self, $body, $header) = @_;
    die "mutateLink must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutateLink',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::mutateLink )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutateManager {
    my ($self, $body, $header) = @_;
    die "mutateManager must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutateManager',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::mutateManager )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201702::ManagedCustomerService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201702::ManagedCustomerService::ManagedCustomerServiceInterfacePort - SOAP Interface for the ManagedCustomerService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201702::ManagedCustomerService::ManagedCustomerServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201702::ManagedCustomerService::ManagedCustomerServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->getPendingInvitations();
 $response = $interface->mutate();
 $response = $interface->mutateLabel();
 $response = $interface->mutateLink();
 $response = $interface->mutateManager();



=head1 DESCRIPTION

SOAP Interface for the ManagedCustomerService web service
located at https://adwords.google.com/api/adwords/mcm/v201702/ManagedCustomerService.

=head1 SERVICE ManagedCustomerService



=head2 Port ManagedCustomerServiceInterfacePort



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

Returns the list of customers that meet the selector criteria. @param selector The selector specifying the {@link ManagedCustomer}s to return. @return List of customers identified by the selector. @throws ApiException When there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201702::ManagedCustomerService::getResponse|Google::Ads::AdWords::v201702::ManagedCustomerService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201702::Selector
  },,
 );

=head3 getPendingInvitations

Returns the pending invitations for the customer IDs in the selector. @param selector the manager customer ids (inviters) or the client customer ids (invitees) @throws ApiException when there is at least one error with the request 

Returns a L<Google::Ads::AdWords::v201702::ManagedCustomerService::getPendingInvitationsResponse|Google::Ads::AdWords::v201702::ManagedCustomerService::getPendingInvitationsResponse> object.

 $response = $interface->getPendingInvitations( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201702::PendingInvitationSelector
  },,
 );

=head3 mutate

Modifies or creates new {@link ManagedCustomer}s. <p class="note"><b>Note:</b> See {@link ManagedCustomerOperation} for available operators.</p> @param operations List of unique operations. @return The list of updated managed customers, returned in the same order as the <code>operations</code> array. 

Returns a L<Google::Ads::AdWords::v201702::ManagedCustomerService::mutateResponse|Google::Ads::AdWords::v201702::ManagedCustomerService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201702::ManagedCustomerOperation
  },,
 );

=head3 mutateLabel

Adds {@linkplain AccountLabel}s to, and removes {@linkplain AccountLabel}s from, {@linkplain ManagedCustomer}s. <p>To add an {@linkplain AccountLabel} to a {@linkplain ManagedCustomer}, use {@link Operator#ADD}. To remove an {@linkplain AccountLabel} from a {@linkplain ManagedCustomer}, use {@link Operator#REMOVE}.</p> <p>The label must already exist (see {@link AccountLabelService#mutate} for how to create them) and be owned by the authenticated user.</p> <p>The {@linkplain ManagedCustomer} must already exist and be managed by the customer making the request (either directly or indirectly).</p> <p>An AccountLabel may be applied to at most 1000 customers.</p> <p>This method does not support partial failures, and will fail if any operation is invalid.</p> 

Returns a L<Google::Ads::AdWords::v201702::ManagedCustomerService::mutateLabelResponse|Google::Ads::AdWords::v201702::ManagedCustomerService::mutateLabelResponse> object.

 $response = $interface->mutateLabel( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201702::ManagedCustomerLabelOperation
  },,
 );

=head3 mutateLink

Modifies the ManagedCustomer forest. These actions are possible (categorized by Operator + Link Status): <ul> <li>ADD + PENDING: manager extends invitations</li> <li>SET + CANCELLED: manager rescinds invitations</li> <li>SET + INACTIVE: manager/client terminates links</li> <li>SET + ACTIVE: client accepts invitations</li> <li>SET + REFUSED: client declines invitations</li> </ul> In addition to these, active links can also be marked hidden / unhidden. <ul> <li> An ACTIVE link can be marked hidden with SET + ACTIVE along with setting the isHidden bit to true. </li> <li> An ACTIVE link can be marked unhidden with SET + ACTIVE along with setting the isHidden bit to false. </li> </ul> @param operations the list of operations @return results for the given operations @throws ApiException with a {@link ManagedCustomerServiceError} 

Returns a L<Google::Ads::AdWords::v201702::ManagedCustomerService::mutateLinkResponse|Google::Ads::AdWords::v201702::ManagedCustomerService::mutateLinkResponse> object.

 $response = $interface->mutateLink( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201702::LinkOperation
  },,
 );

=head3 mutateManager

Moves client customers to new managers (moving links). Only the following action is possible: <ul> <li>SET + ACTIVE: manager moves client customers to new managers within the same manager account hierarchy</li> </ul> @param operations List of unique operations. @return results for the given operations @throws ApiException with a {@link ManagedCustomerServiceError} 

Returns a L<Google::Ads::AdWords::v201702::ManagedCustomerService::mutateManagerResponse|Google::Ads::AdWords::v201702::ManagedCustomerService::mutateManagerResponse> object.

 $response = $interface->mutateManager( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201702::MoveOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Thu May 25 10:02:09 2017

=cut
