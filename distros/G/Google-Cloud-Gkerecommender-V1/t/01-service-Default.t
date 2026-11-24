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
    for my $pkg (qw( Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Gkerecommender::V1;

my $client = Google::Cloud::Gkerecommender::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'fetch_models method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart', 'Correct service path');
        is($args->{method}, 'FetchModels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse'->new();
        return $response;
    };
    
    my $res = $client->fetch_models();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse', 'Response object class');
    done_testing();
};

subtest 'fetch_model_servers method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart', 'Correct service path');
        is($args->{method}, 'FetchModelServers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse'->new();
        return $response;
    };
    
    my $res = $client->fetch_model_servers();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse', 'Response object class');
    done_testing();
};

subtest 'fetch_model_server_versions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart', 'Correct service path');
        is($args->{method}, 'FetchModelServerVersions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse'->new();
        return $response;
    };
    
    my $res = $client->fetch_model_server_versions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse', 'Response object class');
    done_testing();
};

subtest 'fetch_profiles method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart', 'Correct service path');
        is($args->{method}, 'FetchProfiles', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse'->new();
        return $response;
    };
    
    my $res = $client->fetch_profiles();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse', 'Response object class');
    done_testing();
};

subtest 'generate_optimized_manifest method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart', 'Correct service path');
        is($args->{method}, 'GenerateOptimizedManifest', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_optimized_manifest();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse', 'Response object class');
    done_testing();
};

subtest 'fetch_benchmarking_data method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart', 'Correct service path');
        is($args->{method}, 'FetchBenchmarkingData', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse'->new();
        return $response;
    };
    
    my $res = $client->fetch_benchmarking_data();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse', 'Response object class');
    done_testing();
};

done_testing();
