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
    for my $pkg (qw( Google::Dataflow::V1beta3::Metrics::JobExecutionDetails Google::Dataflow::V1beta3::Metrics::JobMetrics Google::Dataflow::V1beta3::Metrics::StageExecutionDetails )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataflow::V1beta3::MetricsV1beta3Client;

my $client = Google::Cloud::Dataflow::V1beta3::MetricsV1beta3Client->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

done_testing();
