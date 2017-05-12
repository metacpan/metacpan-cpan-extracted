package Google::Ads::AdWords::v201609::DataService::DataServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201609::TypeMaps::DataService
    if not Google::Ads::AdWords::v201609::TypeMaps::DataService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201609/DataService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201609::TypeMaps::DataService')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub getAdGroupBidLandscape {
    my ($self, $body, $header) = @_;
    die "getAdGroupBidLandscape must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getAdGroupBidLandscape',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::getAdGroupBidLandscape )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getCampaignCriterionBidLandscape {
    my ($self, $body, $header) = @_;
    die "getCampaignCriterionBidLandscape must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getCampaignCriterionBidLandscape',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::getCampaignCriterionBidLandscape )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getCriterionBidLandscape {
    my ($self, $body, $header) = @_;
    die "getCriterionBidLandscape must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getCriterionBidLandscape',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::getCriterionBidLandscape )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getDomainCategory {
    my ($self, $body, $header) = @_;
    die "getDomainCategory must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getDomainCategory',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::getDomainCategory )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub queryAdGroupBidLandscape {
    my ($self, $body, $header) = @_;
    die "queryAdGroupBidLandscape must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'queryAdGroupBidLandscape',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::queryAdGroupBidLandscape )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub queryCampaignCriterionBidLandscape {
    my ($self, $body, $header) = @_;
    die "queryCampaignCriterionBidLandscape must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'queryCampaignCriterionBidLandscape',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::queryCampaignCriterionBidLandscape )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub queryCriterionBidLandscape {
    my ($self, $body, $header) = @_;
    die "queryCriterionBidLandscape must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'queryCriterionBidLandscape',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::queryCriterionBidLandscape )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub queryDomainCategory {
    my ($self, $body, $header) = @_;
    die "queryDomainCategory must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'queryDomainCategory',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201609::DataService::queryDomainCategory )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201609::DataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201609::DataService::DataServiceInterfacePort - SOAP Interface for the DataService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201609::DataService::DataServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201609::DataService::DataServiceInterfacePort->new();

 my $response;
 $response = $interface->getAdGroupBidLandscape();
 $response = $interface->getCampaignCriterionBidLandscape();
 $response = $interface->getCriterionBidLandscape();
 $response = $interface->getDomainCategory();
 $response = $interface->queryAdGroupBidLandscape();
 $response = $interface->queryCampaignCriterionBidLandscape();
 $response = $interface->queryCriterionBidLandscape();
 $response = $interface->queryDomainCategory();



=head1 DESCRIPTION

SOAP Interface for the DataService web service
located at https://adwords.google.com/api/adwords/cm/v201609/DataService.

=head1 SERVICE DataService



=head2 Port DataServiceInterfacePort



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



=head3 getAdGroupBidLandscape

Returns a list of {@link AdGroupBidLandscape}s for the ad groups specified in the selector. In the result, the returned {@link LandscapePoint}s are grouped into {@link AdGroupBidLandscape}s by their ad groups, and numberResults of paging limits the total number of {@link LandscapePoint}s instead of number of {@link AdGroupBidLandscape}s. @param serviceSelector Selects the entities to return bid landscapes for. @return A list of bid landscapes. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201609::DataService::getAdGroupBidLandscapeResponse|Google::Ads::AdWords::v201609::DataService::getAdGroupBidLandscapeResponse> object.

 $response = $interface->getAdGroupBidLandscape( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201609::Selector
  },,
 );

=head3 getCampaignCriterionBidLandscape

Returns a list of {@link CriterionBidLandscape}s for the campaign criteria specified in the selector. In the result, the returned {@link LandscapePoint}s are grouped into {@link CriterionBidLandscape}s by their campaign id and criterion id, and numberResults of paging limits the total number of {@link LandscapePoint}s instead of number of {@link CriterionBidLandscape}s. @param serviceSelector Selects the entities to return bid landscapes for. @return A list of bid landscapes. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201609::DataService::getCampaignCriterionBidLandscapeResponse|Google::Ads::AdWords::v201609::DataService::getCampaignCriterionBidLandscapeResponse> object.

 $response = $interface->getCampaignCriterionBidLandscape( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201609::Selector
  },,
 );

=head3 getCriterionBidLandscape

Returns a list of {@link CriterionBidLandscape}s for the criteria specified in the selector. In the result, the returned {@link LandscapePoint}s are grouped into {@link CriterionBidLandscape}s by their criteria, and numberResults of paging limits the total number of {@link LandscapePoint}s instead of number of {@link CriterionBidLandscape}s. @param serviceSelector Selects the entities to return bid landscapes for. @return A list of bid landscapes. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201609::DataService::getCriterionBidLandscapeResponse|Google::Ads::AdWords::v201609::DataService::getCriterionBidLandscapeResponse> object.

 $response = $interface->getCriterionBidLandscape( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201609::Selector
  },,
 );

=head3 getDomainCategory

Returns a list of domain categories that can be used to create {@link WebPage} criterion. @param serviceSelector Selects the entities to return domain categories for. @return A list of domain categories. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201609::DataService::getDomainCategoryResponse|Google::Ads::AdWords::v201609::DataService::getDomainCategoryResponse> object.

 $response = $interface->getDomainCategory( {
    serviceSelector =>  $a_reference_to, # see Google::Ads::AdWords::v201609::Selector
  },,
 );

=head3 queryAdGroupBidLandscape

Returns a list of {@link AdGroupBidLandscape}s for the ad groups that match the query. In the result, the returned {@link LandscapePoint}s are grouped into {@link AdGroupBidLandscape}s by their ad groups, and numberResults of paging limits the total number of {@link LandscapePoint}s instead of number of {@link AdGroupBidLandscape}s. @param query The SQL-like AWQL query string. @return A list of bid landscapes. @throws ApiException if problems occur while parsing the query or fetching bid landscapes. 

Returns a L<Google::Ads::AdWords::v201609::DataService::queryAdGroupBidLandscapeResponse|Google::Ads::AdWords::v201609::DataService::queryAdGroupBidLandscapeResponse> object.

 $response = $interface->queryAdGroupBidLandscape( {
    query =>  $some_value, # string
  },,
 );

=head3 queryCampaignCriterionBidLandscape

Returns a list of {@link CriterionBidLandscape}s for the campaign criteria that match the query. In the result, the returned {@link LandscapePoint}s are grouped into {@link CriterionBidLandscape}s by their campaign id and criterion id, and numberResults of paging limits the total number of {@link LandscapePoint}s instead of number of {@link CriterionBidLandscape}s. @param query The SQL-like AWQL query string. @return A list of bid landscapes. @throws ApiException if problems occur while parsing the query or fetching bid landscapes. 

Returns a L<Google::Ads::AdWords::v201609::DataService::queryCampaignCriterionBidLandscapeResponse|Google::Ads::AdWords::v201609::DataService::queryCampaignCriterionBidLandscapeResponse> object.

 $response = $interface->queryCampaignCriterionBidLandscape( {
    query =>  $some_value, # string
  },,
 );

=head3 queryCriterionBidLandscape

Returns a list of {@link CriterionBidLandscape}s for the criteria that match the query. In the result, the returned {@link LandscapePoint}s are grouped into {@link CriterionBidLandscape}s by their criteria, and numberResults of paging limits the total number of {@link LandscapePoint}s instead of number of {@link CriterionBidLandscape}s. @param query The SQL-like AWQL query string. @return A list of bid landscapes. @throws ApiException if problems occur while parsing the query or fetching bid landscapes. 

Returns a L<Google::Ads::AdWords::v201609::DataService::queryCriterionBidLandscapeResponse|Google::Ads::AdWords::v201609::DataService::queryCriterionBidLandscapeResponse> object.

 $response = $interface->queryCriterionBidLandscape( {
    query =>  $some_value, # string
  },,
 );

=head3 queryDomainCategory

Returns a list of domain categories that can be used to create {@link WebPage} criterion. @param query The SQL-like AWQL query string. @return A list of domain categories. @throws ApiException if problems occur while parsing the query or fetching domain categories. 

Returns a L<Google::Ads::AdWords::v201609::DataService::queryDomainCategoryResponse|Google::Ads::AdWords::v201609::DataService::queryDomainCategoryResponse> object.

 $response = $interface->queryDomainCategory( {
    query =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Fri Sep 30 15:11:10 2016

=cut
