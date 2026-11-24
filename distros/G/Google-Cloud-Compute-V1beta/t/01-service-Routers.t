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
    for my $pkg (qw( Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse Google::Cloud::Compute::V1beta::Compute::Operation Google::Cloud::Compute::V1beta::Compute::Router Google::Cloud::Compute::V1beta::Compute::RouterAggregatedList Google::Cloud::Compute::V1beta::Compute::RouterList Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1beta::RoutersClient;

my $client = Google::Cloud::Compute::V1beta::RoutersClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AggregatedListRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RouterAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RouterAggregatedList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'DeleteNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'DeleteRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Router'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Router', 'Response object class');
    done_testing();
};

subtest 'get_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse'->new();
        return $response;
    };
    
    my $res = $client->get_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse', 'Response object class');
    done_testing();
};

subtest 'get_nat_ip_info method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetNatIpInfo', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetNatIpInfoRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse'->new();
        return $response;
    };
    
    my $res = $client->get_nat_ip_info();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse', 'Response object class');
    done_testing();
};

subtest 'get_nat_mapping_info method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetNatMappingInfo', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetNatMappingInfoRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList'->new();
        return $response;
    };
    
    my $res = $client->get_nat_mapping_info();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList', 'Response object class');
    done_testing();
};

subtest 'get_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse'->new();
        return $response;
    };
    
    my $res = $client->get_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse', 'Response object class');
    done_testing();
};

subtest 'get_router_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetRouterStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetRouterStatusRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->get_router_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::InsertRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RouterList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RouterList', 'Response object class');
    done_testing();
};

subtest 'list_bgp_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'ListBgpRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListBgpRoutesRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes'->new();
        return $response;
    };
    
    my $res = $client->list_bgp_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes', 'Response object class');
    done_testing();
};

subtest 'list_named_sets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'ListNamedSets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListNamedSetsRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets'->new();
        return $response;
    };
    
    my $res = $client->list_named_sets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets', 'Response object class');
    done_testing();
};

subtest 'list_route_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'ListRoutePolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListRoutePoliciesRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies'->new();
        return $response;
    };
    
    my $res = $client->list_route_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'PatchNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'PatchRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'preview method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Preview', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PreviewRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse'->new();
        return $response;
    };
    
    my $res = $client->preview();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'update method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'UpdateNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'UpdateRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

done_testing();
