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
    for my $pkg (qw( Google::Devtools::Cloudbuild::V1::Cloudbuild::Build Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Build::V1::CloudBuildClient;

my $client = Google::Cloud::Build::V1::CloudBuildClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_build method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'CreateBuild', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_build();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_build method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'GetBuild', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build'->new();
        return $response;
    };
    
    my $res = $client->get_build();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build', 'Response object class');
    done_testing();
};

subtest 'cancel_build method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'CancelBuild', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CancelBuildRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build'->new();
        return $response;
    };
    
    my $res = $client->cancel_build();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build', 'Response object class');
    done_testing();
};

subtest 'get_build_trigger method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'GetBuildTrigger', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildTriggerRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger'->new();
        return $response;
    };
    
    my $res = $client->get_build_trigger();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger', 'Response object class');
    done_testing();
};

subtest 'delete_build_trigger method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'DeleteBuildTrigger', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteBuildTriggerRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_build_trigger();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'get_worker_pool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'GetWorkerPool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetWorkerPoolRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool'->new();
        return $response;
    };
    
    my $res = $client->get_worker_pool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool', 'Response object class');
    done_testing();
};

subtest 'get_default_service_account method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudbuild.v1.CloudBuild', 'Correct service path');
        is($args->{method}, 'GetDefaultServiceAccount', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetDefaultServiceAccountRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount'->new();
        return $response;
    };
    
    my $res = $client->get_default_service_account();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount', 'Response object class');
    done_testing();
};

done_testing();
