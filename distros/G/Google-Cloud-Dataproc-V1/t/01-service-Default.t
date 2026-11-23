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
    for my $pkg (qw( Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy Google::Cloud::Dataproc::V1::Clusters::Cluster Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse Google::Cloud::Dataproc::V1::Jobs::Job Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataproc::V1;

my $client = Google::Cloud::Dataproc::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_autoscaling_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.AutoscalingPolicyService', 'Correct service path');
        is($args->{method}, 'CreateAutoscalingPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy'->new();
        return $response;
    };
    
    my $res = $client->create_autoscaling_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy', 'Response object class');
    done_testing();
};

subtest 'create_batch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.BatchController', 'Correct service path');
        is($args->{method}, 'CreateBatch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Batches::CreateBatchRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_batch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'CreateCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'UpdateCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'StopCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'start_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'StartCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'DeleteCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'GetCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Clusters::Cluster'->new();
        return $response;
    };
    
    my $res = $client->get_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Clusters::Cluster', 'Response object class');
    done_testing();
};

subtest 'list_clusters method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'ListClusters', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_clusters();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse', 'Response object class');
    done_testing();
};

subtest 'diagnose_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'DiagnoseCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->diagnose_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'submit_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'SubmitJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->submit_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'submit_job_as_operation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'SubmitJobAsOperation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->submit_job_as_operation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'GetJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::GetJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->get_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'list_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'ListJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::ListJobsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse', 'Response object class');
    done_testing();
};

subtest 'update_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'UpdateJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::UpdateJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->update_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'cancel_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'CancelJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::CancelJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Jobs::Job'->new();
        return $response;
    };
    
    my $res = $client->cancel_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Jobs::Job', 'Response object class');
    done_testing();
};

subtest 'delete_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.JobController', 'Correct service path');
        is($args->{method}, 'DeleteJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Jobs::DeleteJobRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'create_node_group method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.NodeGroupController', 'Correct service path');
        is($args->{method}, 'CreateNodeGroup', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_node_group();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.SessionController', 'Correct service path');
        is($args->{method}, 'CreateSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_session_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.SessionTemplateController', 'Correct service path');
        is($args->{method}, 'CreateSessionTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate'->new();
        return $response;
    };
    
    my $res = $client->create_session_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate', 'Response object class');
    done_testing();
};

subtest 'create_workflow_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.WorkflowTemplateService', 'Correct service path');
        is($args->{method}, 'CreateWorkflowTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::WorkflowTemplates::CreateWorkflowTemplateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate'->new();
        return $response;
    };
    
    my $res = $client->create_workflow_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate', 'Response object class');
    done_testing();
};

done_testing();
