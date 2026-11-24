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
    for my $pkg (qw( Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsResponse Google::Cloud::Visionai::V1::Platform::ListApplicationsResponse Google::Cloud::Visionai::V1::StreamingService::Lease Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse Google::Cloud::Visionai::V1::StreamsService::ListClustersResponse Google::Cloud::Visionai::V1::Warehouse::Asset )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Visionai::V1;

my $client = Google::Cloud::Visionai::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'health_check method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.HealthCheckService', 'Correct service path');
        is($args->{method}, 'HealthCheck', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse'->new();
        return $response;
    };
    
    my $res = $client->health_check();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse', 'Response object class');
    done_testing();
};

subtest 'list_public_operators method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.LiveVideoAnalytics', 'Correct service path');
        is($args->{method}, 'ListPublicOperators', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_public_operators();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsResponse', 'Response object class');
    done_testing();
};

subtest 'list_applications method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.AppPlatform', 'Correct service path');
        is($args->{method}, 'ListApplications', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::Platform::ListApplicationsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::Platform::ListApplicationsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_applications();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::Platform::ListApplicationsResponse', 'Response object class');
    done_testing();
};

subtest 'send_packets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.StreamingService', 'Correct service path');
        is($args->{method}, 'SendPackets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse'->new();
        return $response;
    };
    
    my $res = $client->send_packets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse', 'Response object class');
    done_testing();
};

subtest 'receive_packets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.StreamingService', 'Correct service path');
        is($args->{method}, 'ReceivePackets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse'->new();
        return $response;
    };
    
    my $res = $client->receive_packets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse', 'Response object class');
    done_testing();
};

subtest 'receive_events method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.StreamingService', 'Correct service path');
        is($args->{method}, 'ReceiveEvents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse'->new();
        return $response;
    };
    
    my $res = $client->receive_events();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse', 'Response object class');
    done_testing();
};

subtest 'acquire_lease method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.StreamingService', 'Correct service path');
        is($args->{method}, 'AcquireLease', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::StreamingService::Lease'->new();
        return $response;
    };
    
    my $res = $client->acquire_lease();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::StreamingService::Lease', 'Response object class');
    done_testing();
};

subtest 'list_clusters method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.StreamsService', 'Correct service path');
        is($args->{method}, 'ListClusters', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::StreamsService::ListClustersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::StreamsService::ListClustersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_clusters();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::StreamsService::ListClustersResponse', 'Response object class');
    done_testing();
};

subtest 'create_asset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.visionai.v1.Warehouse', 'Correct service path');
        is($args->{method}, 'CreateAsset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Visionai::V1::Warehouse::CreateAssetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Visionai::V1::Warehouse::Asset'->new();
        return $response;
    };
    
    my $res = $client->create_asset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Visionai::V1::Warehouse::Asset', 'Response object class');
    done_testing();
};

done_testing();
