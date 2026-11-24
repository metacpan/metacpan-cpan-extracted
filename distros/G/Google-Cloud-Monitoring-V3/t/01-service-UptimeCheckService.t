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
    for my $pkg (qw( Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Monitoring::V3::UptimeCheckServiceClient;

my $client = Google::Cloud::Monitoring::V3::UptimeCheckServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_uptime_check_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.UptimeCheckService', 'Correct service path');
        is($args->{method}, 'ListUptimeCheckConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_uptime_check_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse', 'Response object class');
    done_testing();
};

subtest 'list_uptime_check_ips method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.monitoring.v3.UptimeCheckService', 'Correct service path');
        is($args->{method}, 'ListUptimeCheckIps', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest', 'Request object');
        
        my $response = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_uptime_check_ips();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse', 'Response object class');
    done_testing();
};

done_testing();
