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
    for my $pkg (qw( Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse Google::Dataflow::V1beta3::Jobs::Job Google::Dataflow::V1beta3::Jobs::ListJobsResponse Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse Google::Dataflow::V1beta3::Metrics::JobExecutionDetails Google::Dataflow::V1beta3::Metrics::JobMetrics Google::Dataflow::V1beta3::Metrics::StageExecutionDetails Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse Google::Dataflow::V1beta3::Snapshots::Snapshot Google::Dataflow::V1beta3::Templates::GetTemplateResponse Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateResponse Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataflow::V1beta3;

my $client = Google::Cloud::Dataflow::V1beta3->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'CreateJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::CreateJobRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->create_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'get_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'GetJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::GetJobRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->get_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'update_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'UpdateJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::UpdateJobRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->update_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'list_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'ListJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::ListJobsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::ListJobsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::ListJobsResponse', 'Response object class');
    done_testing();
};

subtest 'aggregated_list_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'AggregatedListJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::ListJobsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::ListJobsResponse'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::ListJobsResponse', 'Response object class');
    done_testing();
};

subtest 'check_active_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'CheckActiveJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse'->new();
        return $response;
    };
    
    my $res = $client->check_active_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse', 'Response object class');
    done_testing();
};

subtest 'snapshot_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.JobsV1Beta3', 'Correct service path');
        is($args->{method}, 'SnapshotJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Jobs::SnapshotJobRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Snapshots::Snapshot'->new();
        return $response;
    };
    
    my $res = $client->snapshot_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Snapshots::Snapshot', 'Response object class');
    done_testing();
};

subtest 'list_job_messages method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.MessagesV1Beta3', 'Correct service path');
        is($args->{method}, 'ListJobMessages', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_job_messages();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse', 'Response object class');
    done_testing();
};

subtest 'get_job_metrics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.MetricsV1Beta3', 'Correct service path');
        is($args->{method}, 'GetJobMetrics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Metrics::GetJobMetricsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Metrics::JobMetrics'->new();
        return $response;
    };
    
    my $res = $client->get_job_metrics();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Metrics::JobMetrics', 'Response object class');
    done_testing();
};

subtest 'get_job_execution_details method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.MetricsV1Beta3', 'Correct service path');
        is($args->{method}, 'GetJobExecutionDetails', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Metrics::GetJobExecutionDetailsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Metrics::JobExecutionDetails'->new();
        return $response;
    };
    
    my $res = $client->get_job_execution_details();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Metrics::JobExecutionDetails', 'Response object class');
    done_testing();
};

subtest 'get_stage_execution_details method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.MetricsV1Beta3', 'Correct service path');
        is($args->{method}, 'GetStageExecutionDetails', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Metrics::GetStageExecutionDetailsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Metrics::StageExecutionDetails'->new();
        return $response;
    };
    
    my $res = $client->get_stage_execution_details();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Metrics::StageExecutionDetails', 'Response object class');
    done_testing();
};

subtest 'get_snapshot method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.SnapshotsV1Beta3', 'Correct service path');
        is($args->{method}, 'GetSnapshot', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Snapshots::Snapshot'->new();
        return $response;
    };
    
    my $res = $client->get_snapshot();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Snapshots::Snapshot', 'Response object class');
    done_testing();
};

subtest 'delete_snapshot method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.SnapshotsV1Beta3', 'Correct service path');
        is($args->{method}, 'DeleteSnapshot', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse'->new();
        return $response;
    };
    
    my $res = $client->delete_snapshot();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse', 'Response object class');
    done_testing();
};

subtest 'list_snapshots method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.SnapshotsV1Beta3', 'Correct service path');
        is($args->{method}, 'ListSnapshots', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_snapshots();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse', 'Response object class');
    done_testing();
};

subtest 'create_job_from_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.TemplatesService', 'Correct service path');
        is($args->{method}, 'CreateJobFromTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->create_job_from_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'launch_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.TemplatesService', 'Correct service path');
        is($args->{method}, 'LaunchTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Templates::LaunchTemplateRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse'->new();
        return $response;
    };
    
    my $res = $client->launch_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse', 'Response object class');
    done_testing();
};

subtest 'get_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.TemplatesService', 'Correct service path');
        is($args->{method}, 'GetTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Templates::GetTemplateRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Templates::GetTemplateResponse'->new();
        return $response;
    };
    
    my $res = $client->get_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Templates::GetTemplateResponse', 'Response object class');
    done_testing();
};

subtest 'launch_flex_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.dataflow.v1beta3.FlexTemplatesService', 'Correct service path');
        is($args->{method}, 'LaunchFlexTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateRequest', 'Request object');
        
        my $response = 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateResponse'->new();
        return $response;
    };
    
    my $res = $client->launch_flex_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateResponse', 'Response object class');
    done_testing();
};

done_testing();
