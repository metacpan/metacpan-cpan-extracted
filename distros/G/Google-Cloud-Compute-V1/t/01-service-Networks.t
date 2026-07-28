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
    for my $pkg (qw( Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList Google::Cloud::Compute::V1::Compute::Network Google::Cloud::Compute::V1::Compute::NetworkList Google::Cloud::Compute::V1::Compute::NetworksGetEffectiveFirewallsResponse Google::Cloud::Compute::V1::Compute::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1::NetworksClient;

my $client = Google::Cloud::Compute::V1::NetworksClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'add_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'AddPeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::AddPeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'cancel_request_remove_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'CancelRequestRemovePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::CancelRequestRemovePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->cancel_request_remove_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Network'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Network', 'Response object class');
    done_testing();
};

subtest 'get_effective_firewalls method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'GetEffectiveFirewalls', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetEffectiveFirewallsNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::NetworksGetEffectiveFirewallsResponse'->new();
        return $response;
    };
    
    my $res = $client->get_effective_firewalls();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::NetworksGetEffectiveFirewallsResponse', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::InsertNetworkRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListNetworksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::NetworkList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::NetworkList', 'Response object class');
    done_testing();
};

subtest 'list_peering_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'ListPeeringRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListPeeringRoutesNetworksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList'->new();
        return $response;
    };
    
    my $res = $client->list_peering_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PatchNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'RemovePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::RemovePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'request_remove_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'RequestRemovePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::RequestRemovePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->request_remove_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'switch_to_custom_mode method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'SwitchToCustomMode', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::SwitchToCustomModeNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->switch_to_custom_mode();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Networks', 'Correct service path');
        is($args->{method}, 'UpdatePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdatePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

done_testing();
