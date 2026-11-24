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
    for my $pkg (qw( Google::Cloud::Compute::V1beta::Compute::Operation Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse Google::Cloud::Compute::V1beta::Compute::VpnGateway Google::Cloud::Compute::V1beta::Compute::VpnGatewayAggregatedList Google::Cloud::Compute::V1beta::Compute::VpnGatewayList Google::Cloud::Compute::V1beta::Compute::VpnGatewaysGetStatusResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1beta::VpnGatewaysClient;

my $client = Google::Cloud::Compute::V1beta::VpnGatewaysClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AggregatedListVpnGatewaysRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VpnGatewayAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VpnGatewayAggregatedList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteVpnGatewayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetVpnGatewayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VpnGateway'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VpnGateway', 'Response object class');
    done_testing();
};

subtest 'get_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'GetStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetStatusVpnGatewayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VpnGatewaysGetStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->get_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VpnGatewaysGetStatusResponse', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::InsertVpnGatewayRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListVpnGatewaysRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VpnGatewayList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VpnGatewayList', 'Response object class');
    done_testing();
};

subtest 'set_labels method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'SetLabels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetLabelsVpnGatewayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_labels();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsVpnGatewayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

done_testing();
