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
    for my $pkg (qw( Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Authorization Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ChatAppConfig )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Gsuiteaddons::V1::GSuiteAddOnsClient;

my $client = Google::Cloud::Gsuiteaddons::V1::GSuiteAddOnsClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_authorization method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gsuiteaddons.v1.GSuiteAddOns', 'Correct service path');
        is($args->{method}, 'GetAuthorization', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetAuthorizationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Authorization'->new();
        return $response;
    };
    
    my $res = $client->get_authorization();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Authorization', 'Response object class');
    done_testing();
};

subtest 'update_chat_app_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.gsuiteaddons.v1.GSuiteAddOns', 'Correct service path');
        is($args->{method}, 'UpdateChatAppConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UpdateChatAppConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ChatAppConfig'->new();
        return $response;
    };
    
    my $res = $client->update_chat_app_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ChatAppConfig', 'Response object class');
    done_testing();
};

done_testing();
