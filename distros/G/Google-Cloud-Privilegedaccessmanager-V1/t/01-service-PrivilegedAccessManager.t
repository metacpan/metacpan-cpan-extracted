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
    for my $pkg (qw( Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Privilegedaccessmanager::V1::PrivilegedAccessManagerClient;

my $client = Google::Cloud::Privilegedaccessmanager::V1::PrivilegedAccessManagerClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'check_onboarding_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager', 'Correct service path');
        is($args->{method}, 'CheckOnboardingStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusRequest', 'Request object');
        
        my $response = 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->check_onboarding_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse', 'Response object class');
    done_testing();
};

done_testing();
