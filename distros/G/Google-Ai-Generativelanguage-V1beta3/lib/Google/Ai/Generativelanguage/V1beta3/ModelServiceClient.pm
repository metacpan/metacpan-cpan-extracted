package Google::Ai::Generativelanguage::V1beta3::ModelServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta3::Citation;
use Google::Ai::Generativelanguage::V1beta3::Safety;
use Google::Ai::Generativelanguage::V1beta3::TunedModel;
use Google::Ai::Generativelanguage::V1beta3::Model;
use Google::Ai::Generativelanguage::V1beta3::Permission;
use Google::Ai::Generativelanguage::V1beta3::TextService;
use Google::Ai::Generativelanguage::V1beta3::DiscussService;
use Google::Ai::Generativelanguage::V1beta3::ModelService;
use Google::Ai::Generativelanguage::V1beta3::PermissionService;

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
1; # End of Google::Ai::Generativelanguage::V1beta3::ModelServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::ModelServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::ModelServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta3::ModelServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta3::ModelServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta3::ModelServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Ai::Generativelanguage::V1beta3::ModelServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
