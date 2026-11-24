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
    for my $pkg (qw( Google::Devtools::Testing::V1::AdbService::DeviceMessage Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse Google::Devtools::Testing::V1::DirectAccessService::DeviceSession Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TestEnvironmentCatalog Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixResponse Google::Devtools::Testing::V1::TestExecution::TestMatrix )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Devtools::Testing::V1;

my $client = Google::Cloud::Devtools::Testing::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_apk_details method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.ApplicationDetailService', 'Correct service path');
        is($args->{method}, 'GetApkDetails', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse'->new();
        return $response;
    };
    
    my $res = $client->get_apk_details();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse', 'Response object class');
    done_testing();
};

subtest 'create_device_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.DirectAccessService', 'Correct service path');
        is($args->{method}, 'CreateDeviceSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession'->new();
        return $response;
    };
    
    my $res = $client->create_device_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession', 'Response object class');
    done_testing();
};

subtest 'adb_connect method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.DirectAccessService', 'Correct service path');
        is($args->{method}, 'AdbConnect', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::AdbService::AdbMessage', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::AdbService::DeviceMessage'->new();
        return $response;
    };
    
    my $res = $client->adb_connect();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::AdbService::DeviceMessage', 'Response object class');
    done_testing();
};

subtest 'get_test_environment_catalog method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.TestEnvironmentDiscoveryService', 'Correct service path');
        is($args->{method}, 'GetTestEnvironmentCatalog', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::GetTestEnvironmentCatalogRequest', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TestEnvironmentCatalog'->new();
        return $response;
    };
    
    my $res = $client->get_test_environment_catalog();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TestEnvironmentCatalog', 'Response object class');
    done_testing();
};

subtest 'create_test_matrix method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.TestExecutionService', 'Correct service path');
        is($args->{method}, 'CreateTestMatrix', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::TestExecution::CreateTestMatrixRequest', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::TestExecution::TestMatrix'->new();
        return $response;
    };
    
    my $res = $client->create_test_matrix();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::TestExecution::TestMatrix', 'Response object class');
    done_testing();
};

subtest 'get_test_matrix method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.TestExecutionService', 'Correct service path');
        is($args->{method}, 'GetTestMatrix', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::TestExecution::GetTestMatrixRequest', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::TestExecution::TestMatrix'->new();
        return $response;
    };
    
    my $res = $client->get_test_matrix();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::TestExecution::TestMatrix', 'Response object class');
    done_testing();
};

subtest 'cancel_test_matrix method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.testing.v1.TestExecutionService', 'Correct service path');
        is($args->{method}, 'CancelTestMatrix', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixRequest', 'Request object');
        
        my $response = 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixResponse'->new();
        return $response;
    };
    
    my $res = $client->cancel_test_matrix();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Testing::V1::TestExecution::CancelTestMatrixResponse', 'Response object class');
    done_testing();
};

done_testing();
