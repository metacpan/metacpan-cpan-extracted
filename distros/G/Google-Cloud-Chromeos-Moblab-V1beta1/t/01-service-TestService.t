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
    for my $pkg (qw( Google::Chromeos::Moblab::V1beta1::Resources::Session Google::Chromeos::Moblab::V1beta1::Resources::TestEffort Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Chromeos::Moblab::V1beta1::TestServiceClient;

my $client = Google::Cloud::Chromeos::Moblab::V1beta1::TestServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.chromeos.moblab.v1beta1.TestService', 'Correct service path');
        is($args->{method}, 'CreateSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest', 'Request object');
        
        my $response = 'Google::Chromeos::Moblab::V1beta1::Resources::Session'->new();
        return $response;
    };
    
    my $res = $client->create_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Chromeos::Moblab::V1beta1::Resources::Session', 'Response object class');
    done_testing();
};

subtest 'get_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.chromeos.moblab.v1beta1.TestService', 'Correct service path');
        is($args->{method}, 'GetSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest', 'Request object');
        
        my $response = 'Google::Chromeos::Moblab::V1beta1::Resources::Session'->new();
        return $response;
    };
    
    my $res = $client->get_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Chromeos::Moblab::V1beta1::Resources::Session', 'Response object class');
    done_testing();
};

subtest 'list_sessions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.chromeos.moblab.v1beta1.TestService', 'Correct service path');
        is($args->{method}, 'ListSessions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest', 'Request object');
        
        my $response = 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_sessions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse', 'Response object class');
    done_testing();
};

subtest 'list_test_efforts method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.chromeos.moblab.v1beta1.TestService', 'Correct service path');
        is($args->{method}, 'ListTestEfforts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest', 'Request object');
        
        my $response = 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_test_efforts();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse', 'Response object class');
    done_testing();
};

subtest 'cancel_test_effort method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.chromeos.moblab.v1beta1.TestService', 'Correct service path');
        is($args->{method}, 'CancelTestEffort', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest', 'Request object');
        
        my $response = 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse'->new();
        return $response;
    };
    
    my $res = $client->cancel_test_effort();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse', 'Response object class');
    done_testing();
};

subtest 'create_test_effort method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.chromeos.moblab.v1beta1.TestService', 'Correct service path');
        is($args->{method}, 'CreateTestEffort', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest', 'Request object');
        
        my $response = 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort'->new();
        return $response;
    };
    
    my $res = $client->create_test_effort();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort', 'Response object class');
    done_testing();
};

done_testing();
