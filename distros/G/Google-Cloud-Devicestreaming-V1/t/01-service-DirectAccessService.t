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
    for my $pkg (qw( Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage Google::Cloud::Devicestreaming::V1::Service::DeviceSession )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Devicestreaming::V1::DirectAccessServiceClient;

my $client = Google::Cloud::Devicestreaming::V1::DirectAccessServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_device_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.devicestreaming.v1.DirectAccessService', 'Correct service path');
        is($args->{method}, 'CreateDeviceSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession'->new();
        return $response;
    };
    
    my $res = $client->create_device_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession', 'Response object class');
    done_testing();
};

subtest 'adb_connect method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.devicestreaming.v1.DirectAccessService', 'Correct service path');
        is($args->{method}, 'AdbConnect', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Devicestreaming::V1::AdbService::AdbMessage', 'Request object');
        
        my $response = 'Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage'->new();
        return $response;
    };
    
    my $res = $client->adb_connect();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage', 'Response object class');
    done_testing();
};

done_testing();
