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
    for my $pkg (qw( Google::Cloud::Compute::V1::Compute::Operation Google::Cloud::Compute::V1::Compute::Policy Google::Cloud::Compute::V1::Compute::Reservation Google::Cloud::Compute::V1::Compute::ReservationAggregatedList Google::Cloud::Compute::V1::Compute::ReservationList Google::Cloud::Compute::V1::Compute::TestPermissionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1::ReservationsClient;

my $client = Google::Cloud::Compute::V1::ReservationsClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::AggregatedListReservationsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::ReservationAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::ReservationAggregatedList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteReservationRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Reservation'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Reservation', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetIamPolicyReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::InsertReservationRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListReservationsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::ReservationList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::ReservationList', 'Response object class');
    done_testing();
};

subtest 'perform_maintenance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'PerformMaintenance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PerformMaintenanceReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->perform_maintenance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'resize method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'Resize', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ResizeReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->resize();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::SetIamPolicyReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsReservationRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.compute.v1.Reservations', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdateReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

done_testing();
