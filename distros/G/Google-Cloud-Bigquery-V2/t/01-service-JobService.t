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
    for my $pkg (qw( Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse Google::Cloud::Bigquery::V2::Job::Job Google::Cloud::Bigquery::V2::Job::JobCancelResponse Google::Cloud::Bigquery::V2::Job::JobList Google::Cloud::Bigquery::V2::Job::QueryResponse Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigquery::V2::JobServiceClient;

my $client = Google::Cloud::Bigquery::V2::JobServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'cancel_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'CancelJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::CancelJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse'->new();
        return $response;
    };
    
    my $res = $client->cancel_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse', 'Response object class');
    done_testing();
};

subtest 'get_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'GetJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::GetJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::Job'->new();
        return $response;
    };
    
    my $res = $client->get_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::Job', 'Response object class');
    done_testing();
};

subtest 'insert_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'InsertJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::InsertJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::Job'->new();
        return $response;
    };
    
    my $res = $client->insert_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::Job', 'Response object class');
    done_testing();
};

subtest 'delete_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'DeleteJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::DeleteJobRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'ListJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::ListJobsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::JobList'->new();
        return $response;
    };
    
    my $res = $client->list_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::JobList', 'Response object class');
    done_testing();
};

subtest 'get_query_results method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'GetQueryResults', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse'->new();
        return $response;
    };
    
    my $res = $client->get_query_results();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse', 'Response object class');
    done_testing();
};

subtest 'query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'Query', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::PostQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new();
        return $response;
    };
    
    my $res = $client->query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::QueryResponse', 'Response object class');
    done_testing();
};

done_testing();
