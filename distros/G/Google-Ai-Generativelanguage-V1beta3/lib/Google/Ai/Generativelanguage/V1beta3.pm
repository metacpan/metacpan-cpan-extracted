package Google::Ai::Generativelanguage::V1beta3;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta3::Permission;
use Google::Ai::Generativelanguage::V1beta3::Safety;
use Google::Ai::Generativelanguage::V1beta3::Citation;
use Google::Ai::Generativelanguage::V1beta3::TunedModel;
use Google::Ai::Generativelanguage::V1beta3::Model;
use Google::Ai::Generativelanguage::V1beta3::PermissionService;
use Google::Ai::Generativelanguage::V1beta3::DiscussService;
use Google::Ai::Generativelanguage::V1beta3::TextService;
use Google::Ai::Generativelanguage::V1beta3::ModelService;

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

    my $target = 'generativelanguage.googleapis.com:443';
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

sub generate_message {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.DiscussService/GenerateMessage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.DiscussService',
        method         => 'GenerateMessage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_message_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.DiscussService/CountMessageTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.DiscussService',
        method         => 'CountMessageTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::Model::Model';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/GetModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'GetModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/ListModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'ListModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::GetTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/GetTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'GetTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tuned_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/ListTunedModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'ListTunedModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/CreateTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'CreateTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::UpdateTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/UpdateTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'UpdateTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::ModelService::DeleteTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.ModelService/DeleteTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'DeleteTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_permission {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::Permission::Permission';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.PermissionService/CreatePermission',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'CreatePermission',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub transfer_ownership {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.PermissionService/TransferOwnership',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'TransferOwnership',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/GenerateText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'GenerateText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/EmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'EmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/BatchEmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'BatchEmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_text_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/CountTextTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'CountTextTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1beta3

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta3 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta3->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta3->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta3> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1beta3/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1beta3->new(
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

=item * B<generate_message>

    my $response = $client->generate_message(
        model                    => $model,
        prompt                   => $prompt,
        temperature              => $temperature,
        candidate_count          => $candidate_count,
        top_p                    => $top_p,
        top_k                    => $top_k,
    );

Calls the RPC method C<GenerateMessage> on C<google.ai.generativelanguage.v1beta3.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::DiscussService::MessagePrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=back

=item * B<count_message_tokens>

    my $response = $client->count_message_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountMessageTokens> on C<google.ai.generativelanguage.v1beta3.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::DiscussService::MessagePrompt>

=back

=item * B<get_model>

    my $response = $client->get_model(
        name                     => $name,
    );

Calls the RPC method C<GetModel> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::Model::Model>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_models>

    my $response = $client->list_models(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListModels> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_tuned_model>

    my $response = $client->get_tuned_model(
        name                     => $name,
    );

Calls the RPC method C<GetTunedModel> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::GetTunedModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_tuned_models>

    my $response = $client->list_tuned_models(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTunedModels> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_tuned_model>

    my $response = $client->create_tuned_model(
        tuned_model_id           => $tuned_model_id,
        tuned_model              => $tuned_model,
    );

Calls the RPC method C<CreateTunedModel> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tuned_model_id> - C<string>

=item * C<tuned_model> - L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>

=back

=item * B<update_tuned_model>

    my $response = $client->update_tuned_model(
        tuned_model              => $tuned_model,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateTunedModel> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::UpdateTunedModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>

Parameters:

=over 4

=item * C<tuned_model> - L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<delete_tuned_model>

    my $response = $client->delete_tuned_model(
        name                     => $name,
    );

Calls the RPC method C<DeleteTunedModel> on C<google.ai.generativelanguage.v1beta3.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::ModelService::DeleteTunedModelRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_permission>

    my $response = $client->create_permission(
        parent                   => $parent,
        permission               => $permission,
    );

Calls the RPC method C<CreatePermission> on C<google.ai.generativelanguage.v1beta3.PermissionService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::Permission::Permission>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<permission> - L<Google::Ai::Generativelanguage::V1beta3::Permission::Permission>

=back

=item * B<transfer_ownership>

    my $response = $client->transfer_ownership(
        name                     => $name,
        email_address            => $email_address,
    );

Calls the RPC method C<TransferOwnership> on C<google.ai.generativelanguage.v1beta3.PermissionService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<email_address> - C<string>

=back

=item * B<generate_text>

    my $response = $client->generate_text(
        model                    => $model,
        prompt                   => $prompt,
        temperature              => $temperature,
        candidate_count          => $candidate_count,
        max_output_tokens        => $max_output_tokens,
        top_p                    => $top_p,
        top_k                    => $top_k,
        safety_settings          => [ ... ],
        stop_sequences           => [ ... ],
    );

Calls the RPC method C<GenerateText> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<max_output_tokens> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetySetting>

=item * C<stop_sequences> - ArrayRef of C<string>

=back

=item * B<embed_text>

    my $response = $client->embed_text(
        model                    => $model,
        text                     => $text,
    );

Calls the RPC method C<EmbedText> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<text> - C<string>

=back

=item * B<batch_embed_text>

    my $response = $client->batch_embed_text(
        model                    => $model,
        texts                    => [ ... ],
    );

Calls the RPC method C<BatchEmbedText> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<texts> - ArrayRef of C<string>

=back

=item * B<count_text_tokens>

    my $response = $client->count_text_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountTextTokens> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
