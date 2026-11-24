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
    for my $pkg (qw( Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse Google::Cloud::Securitycenter::V2::Source::Source )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Securitycenter::V2::SecurityCenterClient;

my $client = Google::Cloud::Securitycenter::V2::SecurityCenterClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'batch_create_resource_value_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v2.SecurityCenter', 'Correct service path');
        is($args->{method}, 'BatchCreateResourceValueConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_create_resource_value_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse', 'Response object class');
    done_testing();
};

subtest 'create_notification_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v2.SecurityCenter', 'Correct service path');
        is($args->{method}, 'CreateNotificationConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateNotificationConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig'->new();
        return $response;
    };
    
    my $res = $client->create_notification_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig', 'Response object class');
    done_testing();
};

subtest 'list_notification_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v2.SecurityCenter', 'Correct service path');
        is($args->{method}, 'ListNotificationConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_notification_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse', 'Response object class');
    done_testing();
};

subtest 'update_source method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v2.SecurityCenter', 'Correct service path');
        is($args->{method}, 'UpdateSource', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSourceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V2::Source::Source'->new();
        return $response;
    };
    
    my $res = $client->update_source();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V2::Source::Source', 'Response object class');
    done_testing();
};

done_testing();
