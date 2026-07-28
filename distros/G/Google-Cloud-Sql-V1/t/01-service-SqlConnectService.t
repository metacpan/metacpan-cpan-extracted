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
    for my $pkg (qw( Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Sql::V1::SqlConnectServiceClient;

my $client = Google::Cloud::Sql::V1::SqlConnectServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_connect_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlConnectService', 'Correct service path');
        is($args->{method}, 'GetConnectSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings'->new();
        return $response;
    };
    
    my $res = $client->get_connect_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings', 'Response object class');
    done_testing();
};

subtest 'resolve_connect_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlConnectService', 'Correct service path');
        is($args->{method}, 'ResolveConnectSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings'->new();
        return $response;
    };
    
    my $res = $client->resolve_connect_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings', 'Response object class');
    done_testing();
};

subtest 'generate_ephemeral_cert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlConnectService', 'Correct service path');
        is($args->{method}, 'GenerateEphemeralCert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_ephemeral_cert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse', 'Response object class');
    done_testing();
};

done_testing();
