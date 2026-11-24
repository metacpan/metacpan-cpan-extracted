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
    for my $pkg (qw( Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsResponse Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Datalabeling::V1beta1::DataLabelingServiceClient;

my $client = Google::Cloud::Datalabeling::V1beta1::DataLabelingServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.datalabeling.v1beta1.DataLabelingService', 'Correct service path');
        is($args->{method}, 'CreateDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->create_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'list_evaluation_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.datalabeling.v1beta1.DataLabelingService', 'Correct service path');
        is($args->{method}, 'ListEvaluationJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_evaluation_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsResponse', 'Response object class');
    done_testing();
};

done_testing();
