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
    for my $pkg (qw( Google::Cloud::Modelarmor::V1::Service::ListTemplatesResponse Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseResponse Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Modelarmor::V1;

my $client = Google::Cloud::Modelarmor::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_templates method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.modelarmor.v1.ModelArmor', 'Correct service path');
        is($args->{method}, 'ListTemplates', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_templates();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesResponse', 'Response object class');
    done_testing();
};

subtest 'stream_sanitize_user_prompt method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.modelarmor.v1.ModelArmor', 'Correct service path');
        is($args->{method}, 'StreamSanitizeUserPrompt', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptRequest', 'Request object');
        
        my $response = 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_sanitize_user_prompt();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptResponse', 'Response object class');
    done_testing();
};

subtest 'stream_sanitize_model_response method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.modelarmor.v1.ModelArmor', 'Correct service path');
        is($args->{method}, 'StreamSanitizeModelResponse', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseRequest', 'Request object');
        
        my $response = 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_sanitize_model_response();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseResponse', 'Response object class');
    done_testing();
};

done_testing();
