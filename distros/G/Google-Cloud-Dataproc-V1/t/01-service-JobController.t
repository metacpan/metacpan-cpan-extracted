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
    for my $pkg (qw( Google::Cloud::Dataproc::V1::Jobs::Job Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataproc::V1::JobControllerClient;

my $client = Google::Cloud::Dataproc::V1::JobControllerClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

done_testing();
