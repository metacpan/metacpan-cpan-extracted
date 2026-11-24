package Google::Cloud::Dialogflow::Cx::V3beta1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport;
use Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage;
use Google::Cloud::Dialogflow::Cx::V3beta1::ImportStrategy;
use Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock;
use Google::Cloud::Dialogflow::Cx::V3beta1::Inline;
use Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig;
use Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection;
use Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition;
use Google::Cloud::Dialogflow::Cx::V3beta1::Gcs;
use Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall;
use Google::Cloud::Dialogflow::Cx::V3beta1::Experiment;
use Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::Changelog;
use Google::Cloud::Dialogflow::Cx::V3beta1::Deployment;
use Google::Cloud::Dialogflow::Cx::V3beta1::EntityType;
use Google::Cloud::Dialogflow::Cx::V3beta1::Intent;
use Google::Cloud::Dialogflow::Cx::V3beta1::GenerativeSettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::Trace;
use Google::Cloud::Dialogflow::Cx::V3beta1::Tool;
use Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::ResponseMessage;
use Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType;
use Google::Cloud::Dialogflow::Cx::V3beta1::Generator;
use Google::Cloud::Dialogflow::Cx::V3beta1::Example;
use Google::Cloud::Dialogflow::Cx::V3beta1::Webhook;
use Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment;
use Google::Cloud::Dialogflow::Cx::V3beta1::Playbook;
use Google::Cloud::Dialogflow::Cx::V3beta1::Page;
use Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup;
use Google::Cloud::Dialogflow::Cx::V3beta1::Flow;
use Google::Cloud::Dialogflow::Cx::V3beta1::Agent;
use Google::Cloud::Dialogflow::Cx::V3beta1::Version;
use Google::Cloud::Dialogflow::Cx::V3beta1::Session;
use Google::Cloud::Dialogflow::Cx::V3beta1::TestCase;
use Google::Cloud::Dialogflow::Cx::V3beta1::Environment;
use Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory;

our $VERSION = '0.06';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!defined $auth) {
        $auth = Google::Auth->default();
    } elsif (!eval { $auth->can('get_token') }) {
        croak 'Invalid credentials object: must implement get_token()';
    }
    my $token = $auth->get_token();

    my $target = 'dialogflow.googleapis.com:443';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub list_agents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Agents/ListAgents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Agents',
        method         => 'ListAgents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_generative_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetGenerativeSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::GenerativeSettings::GenerativeSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Agents/GetGenerativeSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Agents',
        method         => 'GetGenerativeSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_changelogs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Changelogs/ListChangelogs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Changelogs',
        method         => 'ListChangelogs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_conversations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.ConversationHistory/ListConversations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.ConversationHistory',
        method         => 'ListConversations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_deployments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Deployments/ListDeployments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Deployments',
        method         => 'ListDeployments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_entity_type {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::EntityType::GetEntityTypeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::EntityType::EntityType';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.EntityTypes/GetEntityType',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.EntityTypes',
        method         => 'GetEntityType',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_environments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Environments/ListEnvironments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Environments',
        method         => 'ListEnvironments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_example {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Examples/CreateExample',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Examples',
        method         => 'CreateExample',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_experiments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Experiment::ListExperimentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Experiment::ListExperimentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Experiments/ListExperiments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Experiments',
        method         => 'ListExperiments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_flow {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Flow::CreateFlowRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Flows/CreateFlow',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Flows',
        method         => 'CreateFlow',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_generators {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Generators/ListGenerators',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Generators',
        method         => 'ListGenerators',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_intents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Intent::ListIntentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Intent::ListIntentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Intents/ListIntents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Intents',
        method         => 'ListIntents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_pages {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Page::ListPagesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Page::ListPagesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Pages/ListPages',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Pages',
        method         => 'ListPages',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_playbook {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Playbook::CreatePlaybookRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Playbook::Playbook';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Playbooks/CreatePlaybook',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Playbooks',
        method         => 'CreatePlaybook',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_security_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::CreateSecuritySettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService/CreateSecuritySettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService',
        method         => 'CreateSecuritySettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detect_intent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Sessions/DetectIntent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Sessions',
        method         => 'DetectIntent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_session_entity_types {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes/ListSessionEntityTypes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_test_cases {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::TestCase::ListTestCasesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::TestCase::ListTestCasesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.TestCases/ListTestCases',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TestCases',
        method         => 'ListTestCases',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Tools/CreateTool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Tools',
        method         => 'CreateTool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_transition_route_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups/ListTransitionRouteGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups',
        method         => 'ListTransitionRouteGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_versions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Versions/ListVersions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'ListVersions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_webhooks {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Webhooks/ListWebhooks',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Webhooks',
        method         => 'ListWebhooks',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::Cx::V3beta1

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::Cx::V3beta1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::Cx::V3beta1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::Cx::V3beta1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/advanced_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/agent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/audio_config.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/bigquery_export.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/changelog.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/code_block.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/conversation_history.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/data_store_connection.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/deployment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/environment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/example.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/experiment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/flow.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/fulfillment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/gcs.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/generative_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/generator.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/import_strategy.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/inline.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/intent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/page.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/parameter_definition.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/playbook.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/response_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/safety_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/security_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/session.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/session_entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/test_case.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/tool.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/tool_call.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/trace.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/transition_route_group.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/validation_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/version.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dialogflow::Cx::V3beta1->new(
        credentials => $auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

=head1 ATTRIBUTES

=head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

=head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

=head1 METHODS

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<list_agents>

    my $response = $client->list_agents(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListAgents> on C<google.cloud.dialogflow.cx.v3beta1.Agents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_generative_settings>

    my $response = $client->get_generative_settings(
        name                     => $name,
        language_code            => $language_code,
    );

Calls the RPC method C<GetGenerativeSettings> on C<google.cloud.dialogflow.cx.v3beta1.Agents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetGenerativeSettingsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::GenerativeSettings::GenerativeSettings>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<language_code> - C<string>

=back

=item * B<list_changelogs>

    my $response = $client->list_changelogs(
        parent                   => $parent,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListChangelogs> on C<google.cloud.dialogflow.cx.v3beta1.Changelogs>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_conversations>

    my $response = $client->list_conversations(
        parent                   => $parent,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListConversations> on C<google.cloud.dialogflow.cx.v3beta1.ConversationHistory>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_deployments>

    my $response = $client->list_deployments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListDeployments> on C<google.cloud.dialogflow.cx.v3beta1.Deployments>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_entity_type>

    my $response = $client->get_entity_type(
        name                     => $name,
        language_code            => $language_code,
    );

Calls the RPC method C<GetEntityType> on C<google.cloud.dialogflow.cx.v3beta1.EntityTypes>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::EntityType::GetEntityTypeRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::EntityType::EntityType>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<language_code> - C<string>

=back

=item * B<list_environments>

    my $response = $client->list_environments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListEnvironments> on C<google.cloud.dialogflow.cx.v3beta1.Environments>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_example>

    my $response = $client->create_example(
        parent                   => $parent,
        example                  => $example,
    );

Calls the RPC method C<CreateExample> on C<google.cloud.dialogflow.cx.v3beta1.Examples>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<example> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example>

=back

=item * B<list_experiments>

    my $response = $client->list_experiments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListExperiments> on C<google.cloud.dialogflow.cx.v3beta1.Experiments>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Experiment::ListExperimentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Experiment::ListExperimentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_flow>

    my $response = $client->create_flow(
        parent                   => $parent,
        flow                     => $flow,
        language_code            => $language_code,
    );

Calls the RPC method C<CreateFlow> on C<google.cloud.dialogflow.cx.v3beta1.Flows>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::CreateFlowRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<flow> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow>

=item * C<language_code> - C<string>

=back

=item * B<list_generators>

    my $response = $client->list_generators(
        parent                   => $parent,
        language_code            => $language_code,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListGenerators> on C<google.cloud.dialogflow.cx.v3beta1.Generators>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_intents>

    my $response = $client->list_intents(
        parent                   => $parent,
        language_code            => $language_code,
        intent_view              => $intent_view,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListIntents> on C<google.cloud.dialogflow.cx.v3beta1.Intents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Intent::ListIntentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Intent::ListIntentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<intent_view> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Intent::IntentView>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_pages>

    my $response = $client->list_pages(
        parent                   => $parent,
        language_code            => $language_code,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListPages> on C<google.cloud.dialogflow.cx.v3beta1.Pages>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Page::ListPagesRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Page::ListPagesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_playbook>

    my $response = $client->create_playbook(
        parent                   => $parent,
        playbook                 => $playbook,
    );

Calls the RPC method C<CreatePlaybook> on C<google.cloud.dialogflow.cx.v3beta1.Playbooks>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Playbook::CreatePlaybookRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Playbook::Playbook>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<playbook> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Playbook::Playbook>

=back

=item * B<create_security_settings>

    my $response = $client->create_security_settings(
        parent                   => $parent,
        security_settings        => $security_settings,
    );

Calls the RPC method C<CreateSecuritySettings> on C<google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::CreateSecuritySettingsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<security_settings> - L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings>

=back

=item * B<detect_intent>

    my $response = $client->detect_intent(
        session                  => $session,
        query_params             => $query_params,
        query_input              => $query_input,
        output_audio_config      => $output_audio_config,
        response_view            => $response_view,
    );

Calls the RPC method C<DetectIntent> on C<google.cloud.dialogflow.cx.v3beta1.Sessions>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentResponse>

Parameters:

=over 4

=item * C<session> - C<string>

=item * C<query_params> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters>

=item * C<query_input> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryInput>

=item * C<output_audio_config> - L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::OutputAudioConfig>

=item * C<response_view> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentResponseView>

=back

=item * B<list_session_entity_types>

    my $response = $client->list_session_entity_types(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSessionEntityTypes> on C<google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_test_cases>

    my $response = $client->list_test_cases(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        view                     => $view,
    );

Calls the RPC method C<ListTestCases> on C<google.cloud.dialogflow.cx.v3beta1.TestCases>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::TestCase::ListTestCasesRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::TestCase::ListTestCasesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<view> - L<Google::Cloud::Dialogflow::Cx::V3beta1::TestCase::TestCaseView>

=back

=item * B<create_tool>

    my $response = $client->create_tool(
        parent                   => $parent,
        tool                     => $tool,
    );

Calls the RPC method C<CreateTool> on C<google.cloud.dialogflow.cx.v3beta1.Tools>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<tool> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool>

=back

=item * B<list_transition_route_groups>

    my $response = $client->list_transition_route_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        language_code            => $language_code,
    );

Calls the RPC method C<ListTransitionRouteGroups> on C<google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<language_code> - C<string>

=back

=item * B<list_versions>

    my $response = $client->list_versions(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListVersions> on C<google.cloud.dialogflow.cx.v3beta1.Versions>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_webhooks>

    my $response = $client->list_webhooks(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListWebhooks> on C<google.cloud.dialogflow.cx.v3beta1.Webhooks>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
