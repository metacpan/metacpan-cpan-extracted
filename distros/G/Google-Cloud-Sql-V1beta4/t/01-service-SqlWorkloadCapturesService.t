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
    for my $pkg (qw( Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Sql::V1beta4::SqlWorkloadCapturesServiceClient;

my $client = Google::Cloud::Sql::V1beta4::SqlWorkloadCapturesServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'start method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService', 'Correct service path');
        is($args->{method}, 'Start', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->start();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'stop method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService', 'Correct service path');
        is($args->{method}, 'Stop', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'start_replay method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService', 'Correct service path');
        is($args->{method}, 'StartReplay', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_replay();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_replay method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService', 'Correct service path');
        is($args->{method}, 'StopReplay', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_replay();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse', 'Response object class');
    done_testing();
};

done_testing();
