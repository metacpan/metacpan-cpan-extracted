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
    for my $pkg (qw( Google::Cloud::Ces::V1::AgentService::ListAppsResponse Google::Cloud::Ces::V1::SessionService::RunSessionResponse Google::Cloud::Ces::V1::ToolService::ExecuteToolResponse Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Ces::V1;

my $client = Google::Cloud::Ces::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_apps method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.ces.v1.AgentService', 'Correct service path');
        is($args->{method}, 'ListApps', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Ces::V1::AgentService::ListAppsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Ces::V1::AgentService::ListAppsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_apps();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Ces::V1::AgentService::ListAppsResponse', 'Response object class');
    done_testing();
};

subtest 'run_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.ces.v1.SessionService', 'Correct service path');
        is($args->{method}, 'RunSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Ces::V1::SessionService::RunSessionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Ces::V1::SessionService::RunSessionResponse'->new();
        return $response;
    };
    
    my $res = $client->run_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Ces::V1::SessionService::RunSessionResponse', 'Response object class');
    done_testing();
};

subtest 'execute_tool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.ces.v1.ToolService', 'Correct service path');
        is($args->{method}, 'ExecuteTool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Ces::V1::ToolService::ExecuteToolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Ces::V1::ToolService::ExecuteToolResponse'->new();
        return $response;
    };
    
    my $res = $client->execute_tool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Ces::V1::ToolService::ExecuteToolResponse', 'Response object class');
    done_testing();
};

subtest 'generate_chat_token method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.ces.v1.WidgetService', 'Correct service path');
        is($args->{method}, 'GenerateChatToken', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest', 'Request object');
        
        my $response = 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_chat_token();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse', 'Response object class');
    done_testing();
};

done_testing();
