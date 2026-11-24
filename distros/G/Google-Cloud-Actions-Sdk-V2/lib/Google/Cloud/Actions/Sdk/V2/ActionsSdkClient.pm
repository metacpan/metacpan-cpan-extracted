package Google::Cloud::Actions::Sdk::V2::ActionsSdkClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Actions::Sdk::V2::Manifest;
use Google::Actions::Sdk::V2::Conversation::Suggestion;
use Google::Actions::Sdk::V2::DataFile;
use Google::Actions::Sdk::V2::Action;
use Google::Actions::Sdk::V2::Conversation::Simple;
use Google::Actions::Sdk::V2::ValidationResults;
use Google::Actions::Sdk::V2::ThemeCustomization;
use Google::Actions::Sdk::V2::AccountLinkingSecret;
use Google::Actions::Sdk::V2::Conversation::Image;
use Google::Actions::Sdk::V2::Surface;
use Google::Actions::Sdk::V2::Conversation::List;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt;
use Google::Actions::Sdk::V2::Conversation::Link;
use Google::Actions::Sdk::V2::Conversation::Intent;
use Google::Actions::Sdk::V2::Conversation::Canvas;
use Google::Actions::Sdk::V2::LocalizedSettings;
use Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt;
use Google::Actions::Sdk::V2::AccountLinking;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities;
use Google::Actions::Sdk::V2::Webhook;
use Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay;
use Google::Actions::Sdk::V2::Interactionmodel::EntitySet;
use Google::Actions::Sdk::V2::Conversation::Media;
use Google::Actions::Sdk::V2::Conversation::Collection;
use Google::Actions::Sdk::V2::ReleaseChannel;
use Google::Actions::Sdk::V2::Version;
use Google::Actions::Sdk::V2::Conversation::Card;
use Google::Actions::Sdk::V2::Conversation::Table;
use Google::Actions::Sdk::V2::Interactionmodel::Intent;
use Google::Actions::Sdk::V2::Settings;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType;
use Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType;
use Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType;
use Google::Actions::Sdk::V2::Conversation::Content;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt;
use Google::Actions::Sdk::V2::Interactionmodel::Type::Type;
use Google::Actions::Sdk::V2::Conversation::Prompt;
use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt;
use Google::Actions::Sdk::V2::Conversation::Scene;
use Google::Actions::Sdk::V2::Interactionmodel::EventHandler;
use Google::Actions::Sdk::V2::EventLogs;
use Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent;
use Google::Actions::Sdk::V2::Interactionmodel::IntentEvent;
use Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent;
use Google::Actions::Sdk::V2::Interactionmodel::Slot;
use Google::Actions::Sdk::V2::ActionsTesting;
use Google::Actions::Sdk::V2::Interactionmodel::Scene;
use Google::Actions::Sdk::V2::ConfigFile;
use Google::Actions::Sdk::V2::Files;
use Google::Actions::Sdk::V2::ActionsSdk;

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

    my $target = 'actions.googleapis.com:443';
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

sub write_draft {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::Draft';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/WriteDraft',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'WriteDraft',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub read_version {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/ReadVersion',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ReadVersion',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub encrypt_secret {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/EncryptSecret',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'EncryptSecret',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub decrypt_secret {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/DecryptSecret',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'DecryptSecret',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_sample_projects {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/ListSampleProjects',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ListSampleProjects',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_release_channels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/ListReleaseChannels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ListReleaseChannels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_versions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.actions.sdk.v2.ActionsSdk/ListVersions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ListVersions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Actions::Sdk::V2::ActionsSdkClient

__END__

=head1 NAME

Google::Cloud::Actions::Sdk::V2::ActionsSdkClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Actions::Sdk::V2::ActionsSdkClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Actions::Sdk::V2::ActionsSdkClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Actions::Sdk::V2::ActionsSdkClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Actions::Sdk::V2::ActionsSdkClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/actions/sdk/v2/account_linking.proto>

=item * C<googleapis/google/actions/sdk/v2/account_linking_secret.proto>

=item * C<googleapis/google/actions/sdk/v2/action.proto>

=item * C<googleapis/google/actions/sdk/v2/actions_sdk.proto>

=item * C<googleapis/google/actions/sdk/v2/actions_testing.proto>

=item * C<googleapis/google/actions/sdk/v2/config_file.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/intent.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/canvas.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/card.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/collection.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/content.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/image.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/link.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/list.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/media.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/content/table.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/simple.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/prompt/suggestion.proto>

=item * C<googleapis/google/actions/sdk/v2/conversation/scene.proto>

=item * C<googleapis/google/actions/sdk/v2/data_file.proto>

=item * C<googleapis/google/actions/sdk/v2/event_logs.proto>

=item * C<googleapis/google/actions/sdk/v2/files.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/conditional_event.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/entity_set.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/event_handler.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/global_intent_event.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/intent.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/intent_event.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_canvas_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_card_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_collection_browse_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_collection_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_content_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_image_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_link_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_list_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_media_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/content/static_table_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/static_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/static_simple_prompt.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/suggestion.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/prompt/surface_capabilities.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/scene.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/slot.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/type/class_reference.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/type/entity_display.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/type/free_text_type.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/type/regular_expression_type.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/type/synonym_type.proto>

=item * C<googleapis/google/actions/sdk/v2/interactionmodel/type/type.proto>

=item * C<googleapis/google/actions/sdk/v2/localized_settings.proto>

=item * C<googleapis/google/actions/sdk/v2/manifest.proto>

=item * C<googleapis/google/actions/sdk/v2/release_channel.proto>

=item * C<googleapis/google/actions/sdk/v2/settings.proto>

=item * C<googleapis/google/actions/sdk/v2/surface.proto>

=item * C<googleapis/google/actions/sdk/v2/theme_customization.proto>

=item * C<googleapis/google/actions/sdk/v2/validation_results.proto>

=item * C<googleapis/google/actions/sdk/v2/version.proto>

=item * C<googleapis/google/actions/sdk/v2/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Actions::Sdk::V2::ActionsSdkClient->new(
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

=item * B<write_draft>

    my $response = $client->write_draft(
        parent                   => $parent,
        files                    => $files,
    );

Calls the RPC method C<WriteDraft> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::Draft>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<files> - L<Google::Actions::Sdk::V2::Files::Files>

=back

=item * B<read_version>

    my $response = $client->read_version(
        name                     => $name,
        client_secret_encryption_key_version => $client_secret_encryption_key_version,
    );

Calls the RPC method C<ReadVersion> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<client_secret_encryption_key_version> - C<string>

=back

=item * B<encrypt_secret>

    my $response = $client->encrypt_secret(
        client_secret            => $client_secret,
    );

Calls the RPC method C<EncryptSecret> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse>

Parameters:

=over 4

=item * C<client_secret> - C<string>

=back

=item * B<decrypt_secret>

    my $response = $client->decrypt_secret(
        encrypted_client_secret  => $encrypted_client_secret,
    );

Calls the RPC method C<DecryptSecret> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse>

Parameters:

=over 4

=item * C<encrypted_client_secret> - C<bytes>

=back

=item * B<list_sample_projects>

    my $response = $client->list_sample_projects(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSampleProjects> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_release_channels>

    my $response = $client->list_release_channels(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListReleaseChannels> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_versions>

    my $response = $client->list_versions(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListVersions> on C<google.actions.sdk.v2.ActionsSdk>.

Request: L<Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest>

Returns: L<Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse>

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
