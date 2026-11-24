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
    for my $pkg (qw( Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse Google::Cloud::Asset::V1::AssetService::Feed Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse Google::Cloud::Asset::V1::AssetService::SavedQuery Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Asset::V1::AssetServiceClient;

my $client = Google::Cloud::Asset::V1::AssetServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'export_assets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'ExportAssets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::ExportAssetsRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->export_assets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'batch_get_assets_history method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'BatchGetAssetsHistory', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_get_assets_history();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse', 'Response object class');
    done_testing();
};

subtest 'get_feed method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'GetFeed', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::GetFeedRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::Feed'->new();
        return $response;
    };
    
    my $res = $client->get_feed();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::Feed', 'Response object class');
    done_testing();
};

subtest 'update_feed method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'UpdateFeed', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::UpdateFeedRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::Feed'->new();
        return $response;
    };
    
    my $res = $client->update_feed();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::Feed', 'Response object class');
    done_testing();
};

subtest 'search_all_iam_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'SearchAllIamPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->search_all_iam_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'analyze_iam_policy_longrunning method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'AnalyzeIamPolicyLongrunning', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->analyze_iam_policy_longrunning();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'query_assets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'QueryAssets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::QueryAssetsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse'->new();
        return $response;
    };
    
    my $res = $client->query_assets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse', 'Response object class');
    done_testing();
};

subtest 'get_saved_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'GetSavedQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::GetSavedQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::SavedQuery'->new();
        return $response;
    };
    
    my $res = $client->get_saved_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::SavedQuery', 'Response object class');
    done_testing();
};

subtest 'update_saved_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'UpdateSavedQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::UpdateSavedQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::SavedQuery'->new();
        return $response;
    };
    
    my $res = $client->update_saved_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::SavedQuery', 'Response object class');
    done_testing();
};

subtest 'analyze_org_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'AnalyzeOrgPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->analyze_org_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'analyze_org_policy_governed_assets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.asset.v1.AssetService', 'Correct service path');
        is($args->{method}, 'AnalyzeOrgPolicyGovernedAssets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse'->new();
        return $response;
    };
    
    my $res = $client->analyze_org_policy_governed_assets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse', 'Response object class');
    done_testing();
};

done_testing();
