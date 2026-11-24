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
    for my $pkg (qw( Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse Google::Devtools::Cloudtrace::V1::Trace::Trace Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Devtools::Cloudtrace::V1::TraceServiceClient;

my $client = Google::Cloud::Devtools::Cloudtrace::V1::TraceServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_traces method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudtrace.v1.TraceService', 'Correct service path');
        is($args->{method}, 'ListTraces', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_traces();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse', 'Response object class');
    done_testing();
};

subtest 'get_trace method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudtrace.v1.TraceService', 'Correct service path');
        is($args->{method}, 'GetTrace', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest', 'Request object');
        
        my $response = 'Google::Devtools::Cloudtrace::V1::Trace::Trace'->new();
        return $response;
    };
    
    my $res = $client->get_trace();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Devtools::Cloudtrace::V1::Trace::Trace', 'Response object class');
    done_testing();
};

subtest 'patch_traces method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.devtools.cloudtrace.v1.TraceService', 'Correct service path');
        is($args->{method}, 'PatchTraces', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->patch_traces();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
