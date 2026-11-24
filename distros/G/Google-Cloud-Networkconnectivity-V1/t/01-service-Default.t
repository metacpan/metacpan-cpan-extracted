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
    for my $pkg (qw( Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsResponse Google::Cloud::Networkconnectivity::V1::Hub::ListHubsResponse Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Networkconnectivity::V1;

my $client = Google::Cloud::Networkconnectivity::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_service_connection_maps method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.CrossNetworkAutomationService', 'Correct service path');
        is($args->{method}, 'ListServiceConnectionMaps', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_service_connection_maps();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse', 'Response object class');
    done_testing();
};

subtest 'list_multicloud_data_transfer_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.DataTransferService', 'Correct service path');
        is($args->{method}, 'ListMulticloudDataTransferConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_multicloud_data_transfer_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsResponse', 'Response object class');
    done_testing();
};

subtest 'list_hubs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.HubService', 'Correct service path');
        is($args->{method}, 'ListHubs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::Hub::ListHubsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1::Hub::ListHubsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_hubs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1::Hub::ListHubsResponse', 'Response object class');
    done_testing();
};

subtest 'update_hub method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.HubService', 'Correct service path');
        is($args->{method}, 'UpdateHub', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::Hub::UpdateHubRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_hub();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_internal_ranges method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.InternalRangeService', 'Correct service path');
        is($args->{method}, 'ListInternalRanges', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_internal_ranges();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse', 'Response object class');
    done_testing();
};

subtest 'list_policy_based_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService', 'Correct service path');
        is($args->{method}, 'ListPolicyBasedRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_policy_based_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse', 'Response object class');
    done_testing();
};

subtest 'delete_policy_based_route method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService', 'Correct service path');
        is($args->{method}, 'DeletePolicyBasedRoute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_policy_based_route();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
