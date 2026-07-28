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
    for my $pkg (qw( Google::Cloud::Compute::V1::Compute::InstanceGroup Google::Cloud::Compute::V1::Compute::Operation Google::Cloud::Compute::V1::Compute::RegionInstanceGroupList Google::Cloud::Compute::V1::Compute::RegionInstanceGroupsListInstances Google::Cloud::Compute::V1::Compute::TestPermissionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1::RegionInstanceGroupsClient;

my $client = Google::Cloud::Compute::V1::RegionInstanceGroupsClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.RegionInstanceGroups', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetRegionInstanceGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::InstanceGroup'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::InstanceGroup', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.RegionInstanceGroups', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListRegionInstanceGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupList', 'Response object class');
    done_testing();
};

subtest 'list_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.RegionInstanceGroups', 'Correct service path');
        is($args->{method}, 'ListInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListInstancesRegionInstanceGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupsListInstances'->new();
        return $response;
    };
    
    my $res = $client->list_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupsListInstances', 'Response object class');
    done_testing();
};

subtest 'set_named_ports method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.RegionInstanceGroups', 'Correct service path');
        is($args->{method}, 'SetNamedPorts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::SetNamedPortsRegionInstanceGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_named_ports();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.RegionInstanceGroups', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsRegionInstanceGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

done_testing();
