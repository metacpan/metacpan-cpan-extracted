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
    for my $pkg (qw( Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsResponse Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsResponse Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesResponse Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Networkconnectivity::V1beta;

my $client = Google::Cloud::Networkconnectivity::V1beta->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_multicloud_data_transfer_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1beta.DataTransferService', 'Correct service path');
        is($args->{method}, 'ListMulticloudDataTransferConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_multicloud_data_transfer_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsResponse', 'Response object class');
    done_testing();
};

subtest 'list_hubs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1beta.HubService', 'Correct service path');
        is($args->{method}, 'ListHubs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_hubs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsResponse', 'Response object class');
    done_testing();
};

subtest 'update_hub method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1beta.HubService', 'Correct service path');
        is($args->{method}, 'UpdateHub', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateHubRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_hub();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_policy_based_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService', 'Correct service path');
        is($args->{method}, 'ListPolicyBasedRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_policy_based_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesResponse', 'Response object class');
    done_testing();
};

subtest 'delete_policy_based_route method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService', 'Correct service path');
        is($args->{method}, 'DeletePolicyBasedRoute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::DeletePolicyBasedRouteRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_policy_based_route();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_remote_transport_profiles method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1beta.TransportManager', 'Correct service path');
        is($args->{method}, 'ListRemoteTransportProfiles', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_remote_transport_profiles();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesResponse', 'Response object class');
    done_testing();
};

done_testing();
