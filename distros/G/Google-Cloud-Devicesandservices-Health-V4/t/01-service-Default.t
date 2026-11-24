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
    for my $pkg (qw( Google::Devicesandservices::Health::V4::DataPoints::DataPoint Google::Devicesandservices::Health::V4::HealthProfile::Identity Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesResponse Google::Devicesandservices::Health::V4::HealthProfile::PairedDevice Google::Devicesandservices::Health::V4::HealthProfile::Profile Google::Devicesandservices::Health::V4::HealthProfile::Settings Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Devicesandservices::Health::V4;

my $client = Google::Cloud::Devicesandservices::Health::V4->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_data_point method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.DataPointsService', 'Correct service path');
        is($args->{method}, 'GetDataPoint', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::DataPoints::GetDataPointRequest', 'Request object');
        
        my $response = 'Google::Devicesandservices::Health::V4::DataPoints::DataPoint'->new();
        return $response;
    };
    
    my $res = $client->get_data_point();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devicesandservices::Health::V4::DataPoints::DataPoint', 'Response object class');
    done_testing();
};

subtest 'create_subscriber method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.DataSubscriptionService', 'Correct service path');
        is($args->{method}, 'CreateSubscriber', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_subscriber();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_profile method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.HealthProfileService', 'Correct service path');
        is($args->{method}, 'GetProfile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::HealthProfile::GetProfileRequest', 'Request object');
        
        my $response = 'Google::Devicesandservices::Health::V4::HealthProfile::Profile'->new();
        return $response;
    };
    
    my $res = $client->get_profile();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devicesandservices::Health::V4::HealthProfile::Profile', 'Response object class');
    done_testing();
};

subtest 'get_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.HealthProfileService', 'Correct service path');
        is($args->{method}, 'GetSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::HealthProfile::GetSettingsRequest', 'Request object');
        
        my $response = 'Google::Devicesandservices::Health::V4::HealthProfile::Settings'->new();
        return $response;
    };
    
    my $res = $client->get_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devicesandservices::Health::V4::HealthProfile::Settings', 'Response object class');
    done_testing();
};

subtest 'get_identity method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.HealthProfileService', 'Correct service path');
        is($args->{method}, 'GetIdentity', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::HealthProfile::GetIdentityRequest', 'Request object');
        
        my $response = 'Google::Devicesandservices::Health::V4::HealthProfile::Identity'->new();
        return $response;
    };
    
    my $res = $client->get_identity();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devicesandservices::Health::V4::HealthProfile::Identity', 'Response object class');
    done_testing();
};

subtest 'get_paired_device method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.HealthProfileService', 'Correct service path');
        is($args->{method}, 'GetPairedDevice', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::HealthProfile::GetPairedDeviceRequest', 'Request object');
        
        my $response = 'Google::Devicesandservices::Health::V4::HealthProfile::PairedDevice'->new();
        return $response;
    };
    
    my $res = $client->get_paired_device();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devicesandservices::Health::V4::HealthProfile::PairedDevice', 'Response object class');
    done_testing();
};

subtest 'list_paired_devices method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devicesandservices.health.v4.HealthProfileService', 'Correct service path');
        is($args->{method}, 'ListPairedDevices', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesRequest', 'Request object');
        
        my $response = 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_paired_devices();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesResponse', 'Response object class');
    done_testing();
};

done_testing();
