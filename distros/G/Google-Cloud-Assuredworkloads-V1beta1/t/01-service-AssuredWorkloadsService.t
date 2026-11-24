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
    for my $pkg (qw( Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient;

my $client = Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_workload method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService', 'Correct service path');
        is($args->{method}, 'CreateWorkload', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_workload();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_workload method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService', 'Correct service path');
        is($args->{method}, 'GetWorkload', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest', 'Request object');
        
        my $response = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload'->new();
        return $response;
    };
    
    my $res = $client->get_workload();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload', 'Response object class');
    done_testing();
};

subtest 'analyze_workload_move method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService', 'Correct service path');
        is($args->{method}, 'AnalyzeWorkloadMove', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest', 'Request object');
        
        my $response = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse'->new();
        return $response;
    };
    
    my $res = $client->analyze_workload_move();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse', 'Response object class');
    done_testing();
};

subtest 'list_workloads method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService', 'Correct service path');
        is($args->{method}, 'ListWorkloads', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_workloads();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse', 'Response object class');
    done_testing();
};

done_testing();
