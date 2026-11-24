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
    for my $pkg (qw( Google::Logging::V2::Logging::TailLogEntriesResponse Google::Logging::V2::LoggingConfig::ListBucketsResponse Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Logging::V2;

my $client = Google::Cloud::Logging::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'delete_log method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.logging.v2.LoggingServiceV2', 'Correct service path');
        is($args->{method}, 'DeleteLog', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Logging::V2::Logging::DeleteLogRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_log();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'tail_log_entries method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.logging.v2.LoggingServiceV2', 'Correct service path');
        is($args->{method}, 'TailLogEntries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Logging::V2::Logging::TailLogEntriesRequest', 'Request object');
        
        my $response = 'Google::Logging::V2::Logging::TailLogEntriesResponse'->new();
        return $response;
    };
    
    my $res = $client->tail_log_entries();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Logging::V2::Logging::TailLogEntriesResponse', 'Response object class');
    done_testing();
};

subtest 'list_buckets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.logging.v2.ConfigServiceV2', 'Correct service path');
        is($args->{method}, 'ListBuckets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Logging::V2::LoggingConfig::ListBucketsRequest', 'Request object');
        
        my $response = 'Google::Logging::V2::LoggingConfig::ListBucketsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_buckets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Logging::V2::LoggingConfig::ListBucketsResponse', 'Response object class');
    done_testing();
};

subtest 'copy_log_entries method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.logging.v2.ConfigServiceV2', 'Correct service path');
        is($args->{method}, 'CopyLogEntries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Logging::V2::LoggingConfig::CopyLogEntriesRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->copy_log_entries();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_log_metrics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.logging.v2.MetricsServiceV2', 'Correct service path');
        is($args->{method}, 'ListLogMetrics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest', 'Request object');
        
        my $response = 'Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_log_metrics();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse', 'Response object class');
    done_testing();
};

done_testing();
