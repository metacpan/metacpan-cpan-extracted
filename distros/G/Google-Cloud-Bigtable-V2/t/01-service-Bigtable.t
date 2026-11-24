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
    for my $pkg (qw( Google::Bigtable::V2::Bigtable::ReadRowsResponse Google::Bigtable::V2::Session::ClientConfiguration Google::Bigtable::V2::Session::SessionResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigtable::V2::BigtableClient;

my $client = Google::Cloud::Bigtable::V2::BigtableClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'read_rows method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.v2.Bigtable', 'Correct service path');
        is($args->{method}, 'ReadRows', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::V2::Bigtable::ReadRowsRequest', 'Request object');
        
        my $response = 'Google::Bigtable::V2::Bigtable::ReadRowsResponse'->new();
        return $response;
    };
    
    my $res = $client->read_rows();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::V2::Bigtable::ReadRowsResponse', 'Response object class');
    done_testing();
};

subtest 'get_client_configuration method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.v2.Bigtable', 'Correct service path');
        is($args->{method}, 'GetClientConfiguration', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::V2::Session::GetClientConfigurationRequest', 'Request object');
        
        my $response = 'Google::Bigtable::V2::Session::ClientConfiguration'->new();
        return $response;
    };
    
    my $res = $client->get_client_configuration();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::V2::Session::ClientConfiguration', 'Response object class');
    done_testing();
};

subtest 'open_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.v2.Bigtable', 'Correct service path');
        is($args->{method}, 'OpenTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::V2::Session::SessionRequest', 'Request object');
        
        my $response = 'Google::Bigtable::V2::Session::SessionResponse'->new();
        return $response;
    };
    
    my $res = $client->open_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::V2::Session::SessionResponse', 'Response object class');
    done_testing();
};

subtest 'open_authorized_view method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.v2.Bigtable', 'Correct service path');
        is($args->{method}, 'OpenAuthorizedView', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::V2::Session::SessionRequest', 'Request object');
        
        my $response = 'Google::Bigtable::V2::Session::SessionResponse'->new();
        return $response;
    };
    
    my $res = $client->open_authorized_view();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::V2::Session::SessionResponse', 'Response object class');
    done_testing();
};

subtest 'open_materialized_view method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.v2.Bigtable', 'Correct service path');
        is($args->{method}, 'OpenMaterializedView', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::V2::Session::SessionRequest', 'Request object');
        
        my $response = 'Google::Bigtable::V2::Session::SessionResponse'->new();
        return $response;
    };
    
    my $res = $client->open_materialized_view();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::V2::Session::SessionResponse', 'Response object class');
    done_testing();
};

done_testing();
