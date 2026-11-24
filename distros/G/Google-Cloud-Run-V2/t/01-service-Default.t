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
    for my $pkg (qw( Google::Cloud::Run::V2::Build::SubmitBuildResponse Google::Cloud::Run::V2::Execution::Execution Google::Cloud::Run::V2::Job::Job Google::Cloud::Run::V2::Revision::Revision Google::Cloud::Run::V2::Service::Service Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse Google::Cloud::Run::V2::Task::Task Google::Cloud::Run::V2::WorkerPool::WorkerPool Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Run::V2;

my $client = Google::Cloud::Run::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'submit_build method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Builds', 'Correct service path');
        is($args->{method}, 'SubmitBuild', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Build::SubmitBuildRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::Build::SubmitBuildResponse'->new();
        return $response;
    };
    
    my $res = $client->submit_build();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::Build::SubmitBuildResponse', 'Response object class');
    done_testing();
};

subtest 'get_execution method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Executions', 'Correct service path');
        is($args->{method}, 'GetExecution', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Execution::GetExecutionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::Execution::Execution'->new();
        return $response;
    };
    
    my $res = $client->get_execution();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::Execution::Execution', 'Response object class');
    done_testing();
};

subtest 'create_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Instances', 'Correct service path');
        is($args->{method}, 'CreateInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Instance::CreateInstanceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Instances', 'Correct service path');
        is($args->{method}, 'UpdateInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Instance::UpdateInstanceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Instances', 'Correct service path');
        is($args->{method}, 'StopInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Instance::StopInstanceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Jobs', 'Correct service path');
        is($args->{method}, 'CreateJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Job::CreateJobRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Jobs', 'Correct service path');
        is($args->{method}, 'GetJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Job::GetJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::Job::Job'->new();
        return $response;
    };
    
    my $res = $client->get_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::Job::Job', 'Response object class');
    done_testing();
};

subtest 'update_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Jobs', 'Correct service path');
        is($args->{method}, 'UpdateJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Job::UpdateJobRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_revision method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Revisions', 'Correct service path');
        is($args->{method}, 'GetRevision', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Revision::GetRevisionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::Revision::Revision'->new();
        return $response;
    };
    
    my $res = $client->get_revision();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::Revision::Revision', 'Response object class');
    done_testing();
};

subtest 'create_service method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Services', 'Correct service path');
        is($args->{method}, 'CreateService', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Service::CreateServiceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_service();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_service method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Services', 'Correct service path');
        is($args->{method}, 'GetService', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Service::GetServiceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::Service::Service'->new();
        return $response;
    };
    
    my $res = $client->get_service();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::Service::Service', 'Response object class');
    done_testing();
};

subtest 'update_service method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Services', 'Correct service path');
        is($args->{method}, 'UpdateService', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Service::UpdateServiceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_service();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'upload_source method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.SourceUpload', 'Correct service path');
        is($args->{method}, 'UploadSource', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse'->new();
        return $response;
    };
    
    my $res = $client->upload_source();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse', 'Response object class');
    done_testing();
};

subtest 'get_task method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.Tasks', 'Correct service path');
        is($args->{method}, 'GetTask', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::Task::GetTaskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::Task::Task'->new();
        return $response;
    };
    
    my $res = $client->get_task();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::Task::Task', 'Response object class');
    done_testing();
};

subtest 'create_worker_pool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.WorkerPools', 'Correct service path');
        is($args->{method}, 'CreateWorkerPool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::WorkerPool::CreateWorkerPoolRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_worker_pool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_worker_pool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.WorkerPools', 'Correct service path');
        is($args->{method}, 'GetWorkerPool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::WorkerPool::GetWorkerPoolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Run::V2::WorkerPool::WorkerPool'->new();
        return $response;
    };
    
    my $res = $client->get_worker_pool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Run::V2::WorkerPool::WorkerPool', 'Response object class');
    done_testing();
};

subtest 'update_worker_pool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.run.v2.WorkerPools', 'Correct service path');
        is($args->{method}, 'UpdateWorkerPool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Run::V2::WorkerPool::UpdateWorkerPoolRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_worker_pool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
