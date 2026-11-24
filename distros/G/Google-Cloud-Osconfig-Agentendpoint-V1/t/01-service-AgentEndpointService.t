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
    for my $pkg (qw( Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Osconfig::Agentendpoint::V1::AgentEndpointServiceClient;

my $client = Google::Cloud::Osconfig::Agentendpoint::V1::AgentEndpointServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'receive_task_notification method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'ReceiveTaskNotification', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse'->new();
        return $response;
    };
    
    my $res = $client->receive_task_notification();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse', 'Response object class');
    done_testing();
};

subtest 'start_next_task method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'StartNextTask', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse'->new();
        return $response;
    };
    
    my $res = $client->start_next_task();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse', 'Response object class');
    done_testing();
};

subtest 'report_task_progress method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'ReportTaskProgress', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse'->new();
        return $response;
    };
    
    my $res = $client->report_task_progress();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse', 'Response object class');
    done_testing();
};

subtest 'report_task_complete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'ReportTaskComplete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse'->new();
        return $response;
    };
    
    my $res = $client->report_task_complete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse', 'Response object class');
    done_testing();
};

subtest 'register_agent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'RegisterAgent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse'->new();
        return $response;
    };
    
    my $res = $client->register_agent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse', 'Response object class');
    done_testing();
};

subtest 'report_inventory method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'ReportInventory', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse'->new();
        return $response;
    };
    
    my $res = $client->report_inventory();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse', 'Response object class');
    done_testing();
};

subtest 'report_vm_inventory method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService', 'Correct service path');
        is($args->{method}, 'ReportVmInventory', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse'->new();
        return $response;
    };
    
    my $res = $client->report_vm_inventory();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse', 'Response object class');
    done_testing();
};

done_testing();
