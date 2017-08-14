package Google::Ads::AdWords::v201708::AdGroupCriterionService::AdGroupCriterionServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201708::TypeMaps::AdGroupCriterionService
    if not Google::Ads::AdWords::v201708::TypeMaps::AdGroupCriterionService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201708/AdGroupCriterionService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201708::TypeMaps::AdGroupCriterionService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::mutateLabel )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201708::AdGroupCriterionService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201708::AdGroupCriterionService::AdGroupCriterionServiceInterfacePort - SOAP Interface for the AdGroupCriterionService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201708::AdGroupCriterionService::AdGroupCriterionServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201708::AdGroupCriterionService::AdGroupCriterionServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->mutateLabel();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the AdGroupCriterionService web service
located at https://adwords.google.com/api/adwords/cm/v201708/AdGroupCriterionService.

=head1 SERVICE AdGroupCriterionService



=head2 Port AdGroupCriterionServiceInterfacePort



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

Gets adgroup criteria. @param serviceSelector filters the adgroup criteria to be returned. @return a page (subset) view of the criteria selected @throws ApiException when there is at least one error with the request 

Returns a L<Google::Ads::AdWords::v201708::AdGroupCriterionService::getResponse|Google::Ads::AdWords::v201708::AdGroupCriterionService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201708::Selector
  },,
 );

=head3 mutate

Adds, removes or updates adgroup criteria. @param operations operations to do during checks on keywords to be added. @return added and updated adgroup criteria (without optional parts) @throws ApiException when there is at least one error with the request 

Returns a L<Google::Ads::AdWords::v201708::AdGroupCriterionService::mutateResponse|Google::Ads::AdWords::v201708::AdGroupCriterionService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201708::AdGroupCriterionOperation
  },,
 );

=head3 mutateLabel

Adds labels to the AdGroupCriterion or removes labels from the AdGroupCriterion <p>Add - Apply an existing label to an existing {@linkplain AdGroupCriterion ad group criterion}. The {@code adGroupId} and {@code criterionId} must reference an existing {@linkplain AdGroupCriterion ad group criterion}. The {@code labelId} must reference an existing {@linkplain Label label}. <p>Remove - Removes the link between the specified {@linkplain AdGroupCriterion ad group criterion} and {@linkplain Label label}.</p> @param operations the operations to apply @return a list of AdGroupCriterionLabel where each entry in the list is the result of applying the operation in the input list with the same index. For an add operation, the returned AdGroupCriterionLabel contains the AdGroupId, CriterionId and the LabelId. In the case of a remove operation, the returned AdGroupCriterionLabel will only have AdGroupId and CriterionId. @throws ApiException when there are one or more errors with the request 

Returns a L<Google::Ads::AdWords::v201708::AdGroupCriterionService::mutateLabelResponse|Google::Ads::AdWords::v201708::AdGroupCriterionService::mutateLabelResponse> object.

 $response = $interface->mutateLabel( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201708::AdGroupCriterionLabelOperation
  },,
 );

=head3 query

Returns the list of AdGroupCriterion that match the query. @param query The SQL-like AWQL query string @returns A list of AdGroupCriterion @throws ApiException when the query is invalid or there are errors processing the request. 

Returns a L<Google::Ads::AdWords::v201708::AdGroupCriterionService::queryResponse|Google::Ads::AdWords::v201708::AdGroupCriterionService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Tue Aug  8 22:21:52 2017

=cut
