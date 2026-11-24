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
    for my $pkg (qw( Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse Google::Actions::Sdk::V2::ActionsSdk::Draft Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Actions::Sdk::V2;

my $client = Google::Cloud::Actions::Sdk::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'write_draft method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'WriteDraft', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::Draft'->new();
        return $response;
    };
    
    my $res = $client->write_draft();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::Draft', 'Response object class');
    done_testing();
};

subtest 'read_version method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'ReadVersion', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse'->new();
        return $response;
    };
    
    my $res = $client->read_version();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse', 'Response object class');
    done_testing();
};

subtest 'encrypt_secret method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'EncryptSecret', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse'->new();
        return $response;
    };
    
    my $res = $client->encrypt_secret();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse', 'Response object class');
    done_testing();
};

subtest 'decrypt_secret method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'DecryptSecret', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse'->new();
        return $response;
    };
    
    my $res = $client->decrypt_secret();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse', 'Response object class');
    done_testing();
};

subtest 'list_sample_projects method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'ListSampleProjects', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_sample_projects();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse', 'Response object class');
    done_testing();
};

subtest 'list_release_channels method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'ListReleaseChannels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_release_channels();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse', 'Response object class');
    done_testing();
};

subtest 'list_versions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsSdk', 'Correct service path');
        is($args->{method}, 'ListVersions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_versions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse', 'Response object class');
    done_testing();
};

subtest 'send_interaction method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsTesting', 'Correct service path');
        is($args->{method}, 'SendInteraction', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse'->new();
        return $response;
    };
    
    my $res = $client->send_interaction();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse', 'Response object class');
    done_testing();
};

subtest 'match_intents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsTesting', 'Correct service path');
        is($args->{method}, 'MatchIntents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest', 'Request object');
        
        my $response = 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse'->new();
        return $response;
    };
    
    my $res = $client->match_intents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse', 'Response object class');
    done_testing();
};

subtest 'set_web_and_app_activity_control method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.actions.sdk.v2.ActionsTesting', 'Correct service path');
        is($args->{method}, 'SetWebAndAppActivityControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->set_web_and_app_activity_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
