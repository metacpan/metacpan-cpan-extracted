package Google::Ads::AdWords::v201309::TargetingIdeaService::TargetingIdeaServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201309::TypeMaps::TargetingIdeaService
    if not Google::Ads::AdWords::v201309::TypeMaps::TargetingIdeaService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/o/v201309/TargetingIdeaService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201309::TypeMaps::TargetingIdeaService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201309::TargetingIdeaService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201309::TargetingIdeaService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getBulkKeywordIdeas {
    my ($self, $body, $header) = @_;
    die "getBulkKeywordIdeas must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getBulkKeywordIdeas',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201309::TargetingIdeaService::getBulkKeywordIdeas )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201309::TargetingIdeaService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201309::TargetingIdeaService::TargetingIdeaServiceInterfacePort - SOAP Interface for the TargetingIdeaService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201309::TargetingIdeaService::TargetingIdeaServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201309::TargetingIdeaService::TargetingIdeaServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->getBulkKeywordIdeas();



=head1 DESCRIPTION

SOAP Interface for the TargetingIdeaService web service
located at https://adwords.google.com/api/adwords/o/v201309/TargetingIdeaService.

=head1 SERVICE TargetingIdeaService



=head2 Port TargetingIdeaServiceInterfacePort



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

Returns a page of ideas that match the query described by the specified {@link TargetingIdeaSelector}. <p>The selector must specify a {@code paging} value, with {@code numberResults} set to 800 or less. Large result sets must be composed through multiple calls to this method, advancing the paging {@code startIndex} value by {@code numberResults} with each call. <p>Only a relatively small total number of results will be available through this method. Much larger result sets may be available using {@link #getBulkKeywordIdeas(TargetingIdeaSelector)} at the price of reduced flexibility in selector options. @param selector Query describing the types of results to return when finding matches (similar keyword ideas/placement ideas). @return A {@link TargetingIdeaPage} of results, that is a subset of the list of possible ideas meeting the criteria of the {@link TargetingIdeaSelector}. @throws ApiException If problems occurred while querying for ideas. 

Returns a L<Google::Ads::AdWords::v201309::TargetingIdeaService::getResponse|Google::Ads::AdWords::v201309::TargetingIdeaService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201309::TargetingIdeaSelector
  },,
 );

=head3 getBulkKeywordIdeas

Returns a page of ideas that match the query described by the specified {@link TargetingIdeaSelector}. This method is specialized for returning bulk keyword ideas, and thus the selector must be set for {@link com.google.ads.api.services.targetingideas.attributes.RequestType#IDEAS} and {@link com.google.ads.api.services.common.optimization.attributes.IdeaType#KEYWORD}. A limited, fixed set of attributes will be returned. <p>A single-valued {@link com.google.ads.api.services.targetingideas.search.RelatedToUrlSearchParameter} must be supplied. Single-valued {@link com.google.ads.api.services.targetingideas.search.LanguageSearchParameter} and {@link com.google.ads.api.services.targetingideas.search.LocationSearchParameter} are both optional. Other search parameters compatible with a keyword query may also be supplied. <p>The selector must specify a {@code paging} value, with {@code numberResults} set to 800 or less. If a URL based search is performed it will return up to 100 keywords when the site is not owned, or up to 800 if it is. Number of keywords returned on a keyword based search is up to 800. Large result sets must be composed through multiple calls to this method, advancing the paging {@code startIndex} value by {@code numberResults} with each call. <p>This method can make many more results available than {@link #get(TargetingIdeaSelector)}, but allows less control over the query. For fine-tuned queries that do not need large numbers of results, prefer {@link #get(TargetingIdeaSelector)}. @param selector Query describing the bulk keyword ideas to return. @return A {@link TargetingIdeaPage} of results, that is a subset of the list of possible ideas meeting the criteria of the {@link TargetingIdeaSelector}. @throws ApiException If problems occurred while querying for ideas. 

Returns a L<Google::Ads::AdWords::v201309::TargetingIdeaService::getBulkKeywordIdeasResponse|Google::Ads::AdWords::v201309::TargetingIdeaService::getBulkKeywordIdeasResponse> object.

 $response = $interface->getBulkKeywordIdeas( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201309::TargetingIdeaSelector
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Fri Oct  4 12:05:58 2013

=cut
