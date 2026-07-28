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
    for my $pkg (qw( Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse Google::Cloud::Bigquery::V2::Routine::Routine Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigquery::V2::RoutineServiceClient;

my $client = Google::Cloud::Bigquery::V2::RoutineServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'GetRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::GetRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->get_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'insert_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'InsertRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::InsertRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->insert_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'update_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'UpdateRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::UpdateRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->update_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'delete_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'DeleteRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::DeleteRoutineRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_routines method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'ListRoutines', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_routines();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse', 'Response object class');
    done_testing();
};

done_testing();
