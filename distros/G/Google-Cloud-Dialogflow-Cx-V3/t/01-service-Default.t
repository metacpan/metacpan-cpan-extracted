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
    for my $pkg (qw( Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsResponse Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsResponse Google::Cloud::Dialogflow::Cx::V3::Example::Example Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse Google::Cloud::Dialogflow::Cx::V3::Flow::Flow Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentResponse Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse Google::Cloud::Dialogflow::Cx::V3::Tool::Tool Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dialogflow::Cx::V3;

my $client = Google::Cloud::Dialogflow::Cx::V3->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_agents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Agents', 'Correct service path');
        is($args->{method}, 'ListAgents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_agents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsResponse', 'Response object class');
    done_testing();
};

subtest 'get_generative_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Agents', 'Correct service path');
        is($args->{method}, 'GetGenerativeSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Agent::GetGenerativeSettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings'->new();
        return $response;
    };
    
    my $res = $client->get_generative_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings', 'Response object class');
    done_testing();
};

subtest 'list_changelogs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Changelogs', 'Correct service path');
        is($args->{method}, 'ListChangelogs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_changelogs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse', 'Response object class');
    done_testing();
};

subtest 'list_deployments method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Deployments', 'Correct service path');
        is($args->{method}, 'ListDeployments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_deployments();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse', 'Response object class');
    done_testing();
};

subtest 'get_entity_type method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.EntityTypes', 'Correct service path');
        is($args->{method}, 'GetEntityType', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::EntityType::GetEntityTypeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType'->new();
        return $response;
    };
    
    my $res = $client->get_entity_type();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType', 'Response object class');
    done_testing();
};

subtest 'list_environments method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Environments', 'Correct service path');
        is($args->{method}, 'ListEnvironments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_environments();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsResponse', 'Response object class');
    done_testing();
};

subtest 'create_example method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Examples', 'Correct service path');
        is($args->{method}, 'CreateExample', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Example::Example'->new();
        return $response;
    };
    
    my $res = $client->create_example();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Example::Example', 'Response object class');
    done_testing();
};

subtest 'list_experiments method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Experiments', 'Correct service path');
        is($args->{method}, 'ListExperiments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_experiments();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse', 'Response object class');
    done_testing();
};

subtest 'create_flow method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Flows', 'Correct service path');
        is($args->{method}, 'CreateFlow', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Flow::CreateFlowRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow'->new();
        return $response;
    };
    
    my $res = $client->create_flow();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow', 'Response object class');
    done_testing();
};

subtest 'list_generators method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Generators', 'Correct service path');
        is($args->{method}, 'ListGenerators', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_generators();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse', 'Response object class');
    done_testing();
};

subtest 'list_intents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Intents', 'Correct service path');
        is($args->{method}, 'ListIntents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_intents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse', 'Response object class');
    done_testing();
};

subtest 'list_pages method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Pages', 'Correct service path');
        is($args->{method}, 'ListPages', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_pages();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse', 'Response object class');
    done_testing();
};

subtest 'create_playbook method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Playbooks', 'Correct service path');
        is($args->{method}, 'CreatePlaybook', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook'->new();
        return $response;
    };
    
    my $res = $client->create_playbook();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook', 'Response object class');
    done_testing();
};

subtest 'create_security_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.SecuritySettingsService', 'Correct service path');
        is($args->{method}, 'CreateSecuritySettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings'->new();
        return $response;
    };
    
    my $res = $client->create_security_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings', 'Response object class');
    done_testing();
};

subtest 'detect_intent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Sessions', 'Correct service path');
        is($args->{method}, 'DetectIntent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentResponse'->new();
        return $response;
    };
    
    my $res = $client->detect_intent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentResponse', 'Response object class');
    done_testing();
};

subtest 'list_session_entity_types method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.SessionEntityTypes', 'Correct service path');
        is($args->{method}, 'ListSessionEntityTypes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_session_entity_types();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse', 'Response object class');
    done_testing();
};

subtest 'list_test_cases method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.TestCases', 'Correct service path');
        is($args->{method}, 'ListTestCases', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_test_cases();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse', 'Response object class');
    done_testing();
};

subtest 'create_tool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Tools', 'Correct service path');
        is($args->{method}, 'CreateTool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Tool::CreateToolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Tool::Tool'->new();
        return $response;
    };
    
    my $res = $client->create_tool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Tool::Tool', 'Response object class');
    done_testing();
};

subtest 'list_transition_route_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups', 'Correct service path');
        is($args->{method}, 'ListTransitionRouteGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_transition_route_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'list_versions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Versions', 'Correct service path');
        is($args->{method}, 'ListVersions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_versions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse', 'Response object class');
    done_testing();
};

subtest 'list_webhooks method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.cx.v3.Webhooks', 'Correct service path');
        is($args->{method}, 'ListWebhooks', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksResponse'->new();
        return $response;
    };
    
    my $res = $client->list_webhooks();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksResponse', 'Response object class');
    done_testing();
};

done_testing();
