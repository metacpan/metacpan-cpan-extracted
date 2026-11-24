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
    for my $pkg (qw( Google::Cloud::Channel::V1::ReportsService::ListReportsResponse Google::Cloud::Channel::V1::Service::ListCustomersResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Channel::V1;

my $client = Google::Cloud::Channel::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'run_report_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.channel.v1.CloudChannelReportsService', 'Correct service path');
        is($args->{method}, 'RunReportJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Channel::V1::ReportsService::RunReportJobRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->run_report_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_reports method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.channel.v1.CloudChannelReportsService', 'Correct service path');
        is($args->{method}, 'ListReports', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Channel::V1::ReportsService::ListReportsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Channel::V1::ReportsService::ListReportsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_reports();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Channel::V1::ReportsService::ListReportsResponse', 'Response object class');
    done_testing();
};

subtest 'list_customers method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.channel.v1.CloudChannelService', 'Correct service path');
        is($args->{method}, 'ListCustomers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Channel::V1::Service::ListCustomersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Channel::V1::Service::ListCustomersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_customers();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Channel::V1::Service::ListCustomersResponse', 'Response object class');
    done_testing();
};

done_testing();
