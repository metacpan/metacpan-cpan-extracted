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
    for my $pkg (qw( Google::Cloud::Visionai::V1::StreamingService::Lease Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Visionai::V1::StreamingServiceClient;

my $client = Google::Cloud::Visionai::V1::StreamingServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

done_testing();
