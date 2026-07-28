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
    for my $pkg (qw( Google::Cloud::Compute::V1::Compute::HealthCheck Google::Cloud::Compute::V1::Compute::HealthCheckList Google::Cloud::Compute::V1::Compute::HealthChecksAggregatedList Google::Cloud::Compute::V1::Compute::Operation Google::Cloud::Compute::V1::Compute::TestPermissionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1::HealthChecksClient;

my $client = Google::Cloud::Compute::V1::HealthChecksClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::AggregatedListHealthChecksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::HealthChecksAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::HealthChecksAggregatedList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteHealthCheckRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetHealthCheckRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::HealthCheck'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::HealthCheck', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::InsertHealthCheckRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListHealthChecksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::HealthCheckList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::HealthCheckList', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PatchHealthCheckRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsHealthCheckRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'update method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.HealthChecks', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdateHealthCheckRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

done_testing();
