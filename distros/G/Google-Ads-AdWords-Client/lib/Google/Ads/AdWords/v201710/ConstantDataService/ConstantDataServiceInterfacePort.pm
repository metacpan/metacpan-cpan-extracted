package Google::Ads::AdWords::v201710::ConstantDataService::ConstantDataServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201710::TypeMaps::ConstantDataService
    if not Google::Ads::AdWords::v201710::TypeMaps::ConstantDataService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201710/ConstantDataService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201710::TypeMaps::ConstantDataService')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub getAgeRangeCriterion {
    my ($self, $body, $header) = @_;
    die "getAgeRangeCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getAgeRangeCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getAgeRangeCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getCarrierCriterion {
    my ($self, $body, $header) = @_;
    die "getCarrierCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getCarrierCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getCarrierCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getGenderCriterion {
    my ($self, $body, $header) = @_;
    die "getGenderCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getGenderCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getGenderCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getLanguageCriterion {
    my ($self, $body, $header) = @_;
    die "getLanguageCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getLanguageCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getLanguageCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getMobileAppCategoryCriterion {
    my ($self, $body, $header) = @_;
    die "getMobileAppCategoryCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getMobileAppCategoryCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getMobileAppCategoryCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getMobileDeviceCriterion {
    my ($self, $body, $header) = @_;
    die "getMobileDeviceCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getMobileDeviceCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getMobileDeviceCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getOperatingSystemVersionCriterion {
    my ($self, $body, $header) = @_;
    die "getOperatingSystemVersionCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getOperatingSystemVersionCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getOperatingSystemVersionCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getProductBiddingCategoryData {
    my ($self, $body, $header) = @_;
    die "getProductBiddingCategoryData must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getProductBiddingCategoryData',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getProductBiddingCategoryData )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getUserInterestCriterion {
    my ($self, $body, $header) = @_;
    die "getUserInterestCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getUserInterestCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getUserInterestCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getVerticalCriterion {
    my ($self, $body, $header) = @_;
    die "getVerticalCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getVerticalCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201710::ConstantDataService::getVerticalCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201710::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201710::ConstantDataService::ConstantDataServiceInterfacePort - SOAP Interface for the ConstantDataService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201710::ConstantDataService::ConstantDataServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201710::ConstantDataService::ConstantDataServiceInterfacePort->new();

 my $response;
 $response = $interface->getAgeRangeCriterion();
 $response = $interface->getCarrierCriterion();
 $response = $interface->getGenderCriterion();
 $response = $interface->getLanguageCriterion();
 $response = $interface->getMobileAppCategoryCriterion();
 $response = $interface->getMobileDeviceCriterion();
 $response = $interface->getOperatingSystemVersionCriterion();
 $response = $interface->getProductBiddingCategoryData();
 $response = $interface->getUserInterestCriterion();
 $response = $interface->getVerticalCriterion();



=head1 DESCRIPTION

SOAP Interface for the ConstantDataService web service
located at https://adwords.google.com/api/adwords/cm/v201710/ConstantDataService.

=head1 SERVICE ConstantDataService



=head2 Port ConstantDataServiceInterfacePort



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



=head3 getAgeRangeCriterion

Returns a list of all age range criteria. @return A list of age ranges. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getAgeRangeCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getAgeRangeCriterionResponse> object.

 $response = $interface->getAgeRangeCriterion( {
  },,
 );

=head3 getCarrierCriterion

Returns a list of all carrier criteria. @return A list of carriers. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getCarrierCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getCarrierCriterionResponse> object.

 $response = $interface->getCarrierCriterion( {
  },,
 );

=head3 getGenderCriterion

Returns a list of all gender criteria. @return A list of genders. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getGenderCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getGenderCriterionResponse> object.

 $response = $interface->getGenderCriterion( {
  },,
 );

=head3 getLanguageCriterion

Returns a list of all language criteria. @return A list of languages. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getLanguageCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getLanguageCriterionResponse> object.

 $response = $interface->getLanguageCriterion( {
  },,
 );

=head3 getMobileAppCategoryCriterion

Returns a list of all mobile app category criteria. @return A list of mobile app categories. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getMobileAppCategoryCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getMobileAppCategoryCriterionResponse> object.

 $response = $interface->getMobileAppCategoryCriterion( {
  },,
 );

=head3 getMobileDeviceCriterion

Returns a list of all mobile devices. @return A list of mobile devices. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getMobileDeviceCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getMobileDeviceCriterionResponse> object.

 $response = $interface->getMobileDeviceCriterion( {
  },,
 );

=head3 getOperatingSystemVersionCriterion

Returns a list of all operating system version criteria. @return A list of operating system versions. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getOperatingSystemVersionCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getOperatingSystemVersionCriterionResponse> object.

 $response = $interface->getOperatingSystemVersionCriterion( {
  },,
 );

=head3 getProductBiddingCategoryData

Returns a list of shopping bidding categories. A country predicate must be included in the selector, only {@link Predicate.Operator#EQUALS} and {@link Predicate.Operator#IN} with a single value are supported in the country predicate. An empty parentDimensionType predicate will filter for root categories. @return A list of shopping bidding categories. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getProductBiddingCategoryDataResponse|Google::Ads::AdWords::v201710::ConstantDataService::getProductBiddingCategoryDataResponse> object.

 $response = $interface->getProductBiddingCategoryData( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201710::Selector
  },,
 );

=head3 getUserInterestCriterion

Returns a list of user interests. @param userInterestTaxonomyType The type of taxonomy to use when requesting user interests. @return A list of user interests. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getUserInterestCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getUserInterestCriterionResponse> object.

 $response = $interface->getUserInterestCriterion( {
    userInterestTaxonomyType => $some_value, # ConstantDataService.UserInterestTaxonomyType
  },,
 );

=head3 getVerticalCriterion

Returns a list of content verticals. @return A list of verticals. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201710::ConstantDataService::getVerticalCriterionResponse|Google::Ads::AdWords::v201710::ConstantDataService::getVerticalCriterionResponse> object.

 $response = $interface->getVerticalCriterion( {
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Mon Oct  9 18:29:12 2017

=cut
