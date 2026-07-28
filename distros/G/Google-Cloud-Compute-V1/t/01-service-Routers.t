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
    for my $pkg (qw( Google::Cloud::Compute::V1::Compute::NatIpInfoResponse Google::Cloud::Compute::V1::Compute::Operation Google::Cloud::Compute::V1::Compute::Router Google::Cloud::Compute::V1::Compute::RouterAggregatedList Google::Cloud::Compute::V1::Compute::RouterList Google::Cloud::Compute::V1::Compute::RouterStatusResponse Google::Cloud::Compute::V1::Compute::RoutersGetNamedSetResponse Google::Cloud::Compute::V1::Compute::RoutersGetRoutePolicyResponse Google::Cloud::Compute::V1::Compute::RoutersListBgpRoutes Google::Cloud::Compute::V1::Compute::RoutersListNamedSets Google::Cloud::Compute::V1::Compute::RoutersListRoutePolicies Google::Cloud::Compute::V1::Compute::RoutersPreviewResponse Google::Cloud::Compute::V1::Compute::VmEndpointNatMappingsList )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1::RoutersClient;

my $client = Google::Cloud::Compute::V1::RoutersClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::AggregatedListRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RouterAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RouterAggregatedList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'DeleteNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'DeleteRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Router'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Router', 'Response object class');
    done_testing();
};

subtest 'get_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'GetNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RoutersGetNamedSetResponse'->new();
        return $response;
    };
    
    my $res = $client->get_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RoutersGetNamedSetResponse', 'Response object class');
    done_testing();
};

subtest 'get_nat_ip_info method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'GetNatIpInfo', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetNatIpInfoRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::NatIpInfoResponse'->new();
        return $response;
    };
    
    my $res = $client->get_nat_ip_info();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::NatIpInfoResponse', 'Response object class');
    done_testing();
};

subtest 'get_nat_mapping_info method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'GetNatMappingInfo', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetNatMappingInfoRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::VmEndpointNatMappingsList'->new();
        return $response;
    };
    
    my $res = $client->get_nat_mapping_info();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::VmEndpointNatMappingsList', 'Response object class');
    done_testing();
};

subtest 'get_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'GetRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RoutersGetRoutePolicyResponse'->new();
        return $response;
    };
    
    my $res = $client->get_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RoutersGetRoutePolicyResponse', 'Response object class');
    done_testing();
};

subtest 'get_router_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'GetRouterStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetRouterStatusRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RouterStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->get_router_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RouterStatusResponse', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::InsertRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RouterList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RouterList', 'Response object class');
    done_testing();
};

subtest 'list_bgp_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'ListBgpRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListBgpRoutesRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RoutersListBgpRoutes'->new();
        return $response;
    };
    
    my $res = $client->list_bgp_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RoutersListBgpRoutes', 'Response object class');
    done_testing();
};

subtest 'list_named_sets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'ListNamedSets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListNamedSetsRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RoutersListNamedSets'->new();
        return $response;
    };
    
    my $res = $client->list_named_sets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RoutersListNamedSets', 'Response object class');
    done_testing();
};

subtest 'list_route_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'ListRoutePolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListRoutePoliciesRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RoutersListRoutePolicies'->new();
        return $response;
    };
    
    my $res = $client->list_route_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RoutersListRoutePolicies', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PatchRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'PatchNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PatchNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'PatchRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PatchRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'preview method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'Preview', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PreviewRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RoutersPreviewResponse'->new();
        return $response;
    };
    
    my $res = $client->preview();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RoutersPreviewResponse', 'Response object class');
    done_testing();
};

subtest 'update method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdateRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'UpdateNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdateNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Routers', 'Correct service path');
        is($args->{method}, 'UpdateRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdateRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

done_testing();
