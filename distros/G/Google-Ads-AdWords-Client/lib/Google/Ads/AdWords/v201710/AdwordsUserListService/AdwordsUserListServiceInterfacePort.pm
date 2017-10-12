package Google::Ads::AdWords::v201710::AdwordsUserListService::AdwordsUserListServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201710::TypeMaps::AdwordsUserListService
    if not Google::Ads::AdWords::v201710::TypeMaps::AdwordsUserListService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/rm/v201710/AdwordsUserListService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201710::TypeMaps::AdwordsUserListService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutateMembers {
    my ($self, $body, $header) = @_;
    die "mutateMembers must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutateMembers',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::mutateMembers )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::query )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::AdwordsUserListService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201710::AdwordsUserListService::AdwordsUserListServiceInterfacePort - SOAP Interface for the AdwordsUserListService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201710::AdwordsUserListService::AdwordsUserListServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201710::AdwordsUserListService::AdwordsUserListServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();
 $response = $interface->mutateMembers();
 $response = $interface->query();



=head1 DESCRIPTION

SOAP Interface for the AdwordsUserListService web service
located at https://adwords.google.com/api/adwords/rm/v201710/AdwordsUserListService.

=head1 SERVICE AdwordsUserListService



=head2 Port AdwordsUserListServiceInterfacePort



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

Returns the list of user lists that meet the selector criteria. @param serviceSelector the selector specifying the {@link UserList}s to return. @return a list of UserList entities which meet the selector criteria. @throws ApiException if problems occurred while fetching UserList information. 

Returns a L<Google::Ads::AdWords::v201710::AdwordsUserListService::getResponse|Google::Ads::AdWords::v201710::AdwordsUserListService::getResponse> object.

 $response = $interface->get( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201710::Selector
  },,
 );

=head3 mutate

Applies a list of mutate operations (i.e. add, set): Add - creates a set of user lists Set - updates a set of user lists Remove - not supported @param operations the operations to apply @return a list of UserList objects 

Returns a L<Google::Ads::AdWords::v201710::AdwordsUserListService::mutateResponse|Google::Ads::AdWords::v201710::AdwordsUserListService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201710::UserListOperation
  },,
 );

=head3 mutateMembers

Mutate members of user lists by either adding or removing their lists of members. The following {@link Operator}s are supported: ADD and REMOVE. The SET operator is not supported. <p>Note that operations cannot have same user list id but different operators. @param operations the mutate members operations to apply @return a list of UserList objects @throws ApiException when there are one or more errors with the request 

Returns a L<Google::Ads::AdWords::v201710::AdwordsUserListService::mutateMembersResponse|Google::Ads::AdWords::v201710::AdwordsUserListService::mutateMembersResponse> object.

 $response = $interface->mutateMembers( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201710::MutateMembersOperation
  },,
 );

=head3 query

Returns the list of user lists that match the query. @param query The SQL-like AWQL query string @return A list of UserList @throws ApiException when the query is invalid or there are errors processing the request. 

Returns a L<Google::Ads::AdWords::v201710::AdwordsUserListService::queryResponse|Google::Ads::AdWords::v201710::AdwordsUserListService::queryResponse> object.

 $response = $interface->query( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Oct  9 18:30:33 2017

=cut
