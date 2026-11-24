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
    for my $pkg (qw( Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse Google::Monitoring::V3::GroupService::ListGroupsResponse Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse Google::Monitoring::V3::MetricService::ListTimeSeriesResponse Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse Google::Monitoring::V3::Service::Service Google::Monitoring::V3::Snooze::Snooze Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Monitoring::V3;

my $client = Google::Cloud::Monitoring::V3->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_alert_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.AlertPolicyService', 'Correct service path');
        is($args->{method}, 'ListAlertPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_alert_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'list_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.GroupService', 'Correct service path');
        is($args->{method}, 'ListGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::GroupService::ListGroupsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::GroupService::ListGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::GroupService::ListGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'list_monitored_resource_descriptors method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.MetricService', 'Correct service path');
        is($args->{method}, 'ListMonitoredResourceDescriptors', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_monitored_resource_descriptors();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse', 'Response object class');
    done_testing();
};

subtest 'list_time_series method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.MetricService', 'Correct service path');
        is($args->{method}, 'ListTimeSeries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::MetricService::ListTimeSeriesRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::MetricService::ListTimeSeriesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_time_series();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::MetricService::ListTimeSeriesResponse', 'Response object class');
    done_testing();
};

subtest 'create_time_series method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.MetricService', 'Correct service path');
        is($args->{method}, 'CreateTimeSeries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->create_time_series();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'create_service_time_series method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.MetricService', 'Correct service path');
        is($args->{method}, 'CreateServiceTimeSeries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->create_service_time_series();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_notification_channel_descriptors method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.NotificationChannelService', 'Correct service path');
        is($args->{method}, 'ListNotificationChannelDescriptors', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_notification_channel_descriptors();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse', 'Response object class');
    done_testing();
};

subtest 'query_time_series method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.QueryService', 'Correct service path');
        is($args->{method}, 'QueryTimeSeries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse'->new();
        return $response;
    };
    
    my $res = $client->query_time_series();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse', 'Response object class');
    done_testing();
};

subtest 'create_service method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.ServiceMonitoringService', 'Correct service path');
        is($args->{method}, 'CreateService', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::ServiceService::CreateServiceRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::Service::Service'->new();
        return $response;
    };
    
    my $res = $client->create_service();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::Service::Service', 'Response object class');
    done_testing();
};

subtest 'update_service method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.ServiceMonitoringService', 'Correct service path');
        is($args->{method}, 'UpdateService', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::ServiceService::UpdateServiceRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::Service::Service'->new();
        return $response;
    };
    
    my $res = $client->update_service();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::Service::Service', 'Response object class');
    done_testing();
};

subtest 'create_snooze method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.SnoozeService', 'Correct service path');
        is($args->{method}, 'CreateSnooze', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::Snooze::Snooze'->new();
        return $response;
    };
    
    my $res = $client->create_snooze();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::Snooze::Snooze', 'Response object class');
    done_testing();
};

subtest 'list_uptime_check_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.UptimeCheckService', 'Correct service path');
        is($args->{method}, 'ListUptimeCheckConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_uptime_check_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse', 'Response object class');
    done_testing();
};

subtest 'list_uptime_check_ips method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.UptimeCheckService', 'Correct service path');
        is($args->{method}, 'ListUptimeCheckIps', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_uptime_check_ips();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse', 'Response object class');
    done_testing();
};

done_testing();
