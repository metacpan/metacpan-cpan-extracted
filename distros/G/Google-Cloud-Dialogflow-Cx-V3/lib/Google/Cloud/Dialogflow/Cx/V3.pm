package Google::Cloud::Dialogflow::Cx::V3;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dialogflow::Cx::V3::ValidationMessage;
use Google::Cloud::Dialogflow::Cx::V3::ImportStrategy;
use Google::Cloud::Dialogflow::Cx::V3::Inline;
use Google::Cloud::Dialogflow::Cx::V3::Gcs;
use Google::Cloud::Dialogflow::Cx::V3::AudioConfig;
use Google::Cloud::Dialogflow::Cx::V3::Trace;
use Google::Cloud::Dialogflow::Cx::V3::SafetySettings;
use Google::Cloud::Dialogflow::Cx::V3::ToolCall;
use Google::Cloud::Dialogflow::Cx::V3::CodeBlock;
use Google::Cloud::Dialogflow::Cx::V3::DataStoreConnection;
use Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition;
use Google::Cloud::Dialogflow::Cx::V3::Experiment;
use Google::Cloud::Dialogflow::Cx::V3::Changelog;
use Google::Cloud::Dialogflow::Cx::V3::Deployment;
use Google::Cloud::Dialogflow::Cx::V3::SecuritySettings;
use Google::Cloud::Dialogflow::Cx::V3::EntityType;
use Google::Cloud::Dialogflow::Cx::V3::Intent;
use Google::Cloud::Dialogflow::Cx::V3::AdvancedSettings;
use Google::Cloud::Dialogflow::Cx::V3::Example;
use Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings;
use Google::Cloud::Dialogflow::Cx::V3::ResponseMessage;
use Google::Cloud::Dialogflow::Cx::V3::Tool;
use Google::Cloud::Dialogflow::Cx::V3::SessionEntityType;
use Google::Cloud::Dialogflow::Cx::V3::Generator;
use Google::Cloud::Dialogflow::Cx::V3::Webhook;
use Google::Cloud::Dialogflow::Cx::V3::Fulfillment;
use Google::Cloud::Dialogflow::Cx::V3::Page;
use Google::Cloud::Dialogflow::Cx::V3::Playbook;
use Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup;
use Google::Cloud::Dialogflow::Cx::V3::Flow;
use Google::Cloud::Dialogflow::Cx::V3::Version;
use Google::Cloud::Dialogflow::Cx::V3::Session;
use Google::Cloud::Dialogflow::Cx::V3::Agent;
use Google::Cloud::Dialogflow::Cx::V3::TestCase;
use Google::Cloud::Dialogflow::Cx::V3::Environment;

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

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Agents/ListAgents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Agents',
        method         => 'ListAgents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_generative_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Agent::GetGenerativeSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Agents/GetGenerativeSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Agents',
        method         => 'GetGenerativeSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_changelogs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Changelogs/ListChangelogs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Changelogs',
        method         => 'ListChangelogs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_deployments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Deployments/ListDeployments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Deployments',
        method         => 'ListDeployments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_entity_type {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::EntityType::GetEntityTypeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.EntityTypes/GetEntityType',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.EntityTypes',
        method         => 'GetEntityType',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_environments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Environments/ListEnvironments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Environments',
        method         => 'ListEnvironments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_example {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Example::Example';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Examples/CreateExample',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Examples',
        method         => 'CreateExample',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_experiments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Experiments/ListExperiments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Experiments',
        method         => 'ListExperiments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_flow {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Flow::CreateFlowRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Flows/CreateFlow',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Flows',
        method         => 'CreateFlow',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_generators {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Generators/ListGenerators',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Generators',
        method         => 'ListGenerators',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_intents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Intents/ListIntents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Intents',
        method         => 'ListIntents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_pages {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Pages/ListPages',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Pages',
        method         => 'ListPages',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_playbook {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Playbooks/CreatePlaybook',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Playbooks',
        method         => 'CreatePlaybook',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_security_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.SecuritySettingsService/CreateSecuritySettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.SecuritySettingsService',
        method         => 'CreateSecuritySettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detect_intent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Sessions/DetectIntent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Sessions',
        method         => 'DetectIntent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_session_entity_types {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.SessionEntityTypes/ListSessionEntityTypes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_test_cases {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.TestCases/ListTestCases',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.TestCases',
        method         => 'ListTestCases',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Tool::CreateToolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Tool::Tool';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Tools/CreateTool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Tools',
        method         => 'CreateTool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_transition_route_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.TransitionRouteGroups/ListTransitionRouteGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups',
        method         => 'ListTransitionRouteGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_versions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Versions/ListVersions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'ListVersions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_webhooks {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Webhooks/ListWebhooks',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Webhooks',
        method         => 'ListWebhooks',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::Cx::V3

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::Cx::V3->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::Cx::V3->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::Cx::V3> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dialogflow/cx/v3/advanced_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/agent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/audio_config.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/changelog.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/code_block.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/data_store_connection.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/deployment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/environment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/example.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/experiment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/flow.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/fulfillment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/gcs.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/generative_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/generator.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/import_strategy.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/inline.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/intent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/page.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/parameter_definition.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/playbook.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/response_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/safety_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/security_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/session.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/session_entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/test_case.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/tool.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/tool_call.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/trace.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/transition_route_group.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/validation_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/version.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dialogflow::Cx::V3->new(
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

Calls the RPC method C<ListAgents> on C<google.cloud.dialogflow.cx.v3.Agents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Agent::ListAgentsResponse>

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

Calls the RPC method C<GetGenerativeSettings> on C<google.cloud.dialogflow.cx.v3.Agents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Agent::GetGenerativeSettingsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings>

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

Calls the RPC method C<ListChangelogs> on C<google.cloud.dialogflow.cx.v3.Changelogs>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse>

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

Calls the RPC method C<ListDeployments> on C<google.cloud.dialogflow.cx.v3.Deployments>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse>

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

Calls the RPC method C<GetEntityType> on C<google.cloud.dialogflow.cx.v3.EntityTypes>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::EntityType::GetEntityTypeRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType>

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

Calls the RPC method C<ListEnvironments> on C<google.cloud.dialogflow.cx.v3.Environments>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Environment::ListEnvironmentsResponse>

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

Calls the RPC method C<CreateExample> on C<google.cloud.dialogflow.cx.v3.Examples>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Example::Example>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<example> - L<Google::Cloud::Dialogflow::Cx::V3::Example::Example>

=back

=item * B<list_experiments>

    my $response = $client->list_experiments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListExperiments> on C<google.cloud.dialogflow.cx.v3.Experiments>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse>

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

Calls the RPC method C<CreateFlow> on C<google.cloud.dialogflow.cx.v3.Flows>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Flow::CreateFlowRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Flow::Flow>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<flow> - L<Google::Cloud::Dialogflow::Cx::V3::Flow::Flow>

=item * C<language_code> - C<string>

=back

=item * B<list_generators>

    my $response = $client->list_generators(
        parent                   => $parent,
        language_code            => $language_code,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListGenerators> on C<google.cloud.dialogflow.cx.v3.Generators>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse>

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

Calls the RPC method C<ListIntents> on C<google.cloud.dialogflow.cx.v3.Intents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<intent_view> - L<Google::Cloud::Dialogflow::Cx::V3::Intent::IntentView>

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

Calls the RPC method C<ListPages> on C<google.cloud.dialogflow.cx.v3.Pages>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse>

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

Calls the RPC method C<CreatePlaybook> on C<google.cloud.dialogflow.cx.v3.Playbooks>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<playbook> - L<Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook>

=back

=item * B<create_security_settings>

    my $response = $client->create_security_settings(
        parent                   => $parent,
        security_settings        => $security_settings,
    );

Calls the RPC method C<CreateSecuritySettings> on C<google.cloud.dialogflow.cx.v3.SecuritySettingsService>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<security_settings> - L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings>

=back

=item * B<detect_intent>

    my $response = $client->detect_intent(
        session                  => $session,
        query_params             => $query_params,
        query_input              => $query_input,
        output_audio_config      => $output_audio_config,
        response_view            => $response_view,
    );

Calls the RPC method C<DetectIntent> on C<google.cloud.dialogflow.cx.v3.Sessions>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentResponse>

Parameters:

=over 4

=item * C<session> - C<string>

=item * C<query_params> - L<Google::Cloud::Dialogflow::Cx::V3::Session::QueryParameters>

=item * C<query_input> - L<Google::Cloud::Dialogflow::Cx::V3::Session::QueryInput>

=item * C<output_audio_config> - L<Google::Cloud::Dialogflow::Cx::V3::AudioConfig::OutputAudioConfig>

=item * C<response_view> - L<Google::Cloud::Dialogflow::Cx::V3::Session::DetectIntentResponseView>

=back

=item * B<list_session_entity_types>

    my $response = $client->list_session_entity_types(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSessionEntityTypes> on C<google.cloud.dialogflow.cx.v3.SessionEntityTypes>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse>

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

Calls the RPC method C<ListTestCases> on C<google.cloud.dialogflow.cx.v3.TestCases>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<view> - L<Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseView>

=back

=item * B<create_tool>

    my $response = $client->create_tool(
        parent                   => $parent,
        tool                     => $tool,
    );

Calls the RPC method C<CreateTool> on C<google.cloud.dialogflow.cx.v3.Tools>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Tool::CreateToolRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Tool::Tool>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<tool> - L<Google::Cloud::Dialogflow::Cx::V3::Tool::Tool>

=back

=item * B<list_transition_route_groups>

    my $response = $client->list_transition_route_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        language_code            => $language_code,
    );

Calls the RPC method C<ListTransitionRouteGroups> on C<google.cloud.dialogflow.cx.v3.TransitionRouteGroups>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse>

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

Calls the RPC method C<ListVersions> on C<google.cloud.dialogflow.cx.v3.Versions>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse>

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

Calls the RPC method C<ListWebhooks> on C<google.cloud.dialogflow.cx.v3.Webhooks>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Webhook::ListWebhooksResponse>

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
