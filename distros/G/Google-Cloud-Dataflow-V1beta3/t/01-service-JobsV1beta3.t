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
    for my $pkg (qw( Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse Google::Dataflow::V1beta3::Jobs::Job Google::Dataflow::V1beta3::Jobs::ListJobsResponse Google::Dataflow::V1beta3::Snapshots::Snapshot )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataflow::V1beta3::JobsV1beta3Client;

my $client = Google::Cloud::Dataflow::V1beta3::JobsV1beta3Client->new( credentials => 'dummy' );
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

done_testing();
