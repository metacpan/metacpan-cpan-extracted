use strict;
use warnings;
use Test::More;
use File::Spec;

# A. Mock Google::Auth
package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default {
    my ($class, %args) = @_;
    return bless \%args, 'Google::Auth::MockCredentials';
}
package Google::Auth::MockCredentials;
sub get_token {
    return 'mock-token';
}

# B. Mock Google::gRPC::Client
package Google::gRPC::Client;
BEGIN { $INC{'Google/gRPC/Client.pm'} = 1; }
sub new {
    my $class = shift;
    my $args = ( @_ == 1 && ref($_[0]) eq 'HASH' ) ? $_[0] : { @_ };
    return bless $args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Fallback Mocks for External Response Classes
BEGIN {
    for my $pkg (qw( Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Discoveryengine::V1::SiteSearchEngineServiceClient;

my $client = Google::Cloud::Discoveryengine::V1::SiteSearchEngineServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_site_search_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'GetSiteSearchEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::GetSiteSearchEngineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine'->new();
        return $response;
    };
    
    my $res = $client->get_site_search_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine', 'Response object class');
    done_testing();
};

subtest 'batch_create_target_sites method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'BatchCreateTargetSites', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::BatchCreateTargetSitesRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->batch_create_target_sites();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_sitemap method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'CreateSitemap', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::CreateSitemapRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_sitemap();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'enable_advanced_site_search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'EnableAdvancedSiteSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::EnableAdvancedSiteSearchRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->enable_advanced_site_search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'recrawl_uris method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'RecrawlUris', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::RecrawlUrisRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->recrawl_uris();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
