package Google::Cloud::Devtools::Artifactregistry::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Devtools::Artifactregistry::V1::Tag;
use Google::Devtools::Artifactregistry::V1::KfpArtifact;
use Google::Devtools::Artifactregistry::V1::Settings;
use Google::Devtools::Artifactregistry::V1::Package;
use Google::Devtools::Artifactregistry::V1::File;
use Google::Devtools::Artifactregistry::V1::Generic;
use Google::Devtools::Artifactregistry::V1::Go;
use Google::Devtools::Artifactregistry::V1::Attachment;
use Google::Devtools::Artifactregistry::V1::YumArtifact;
use Google::Devtools::Artifactregistry::V1::Artifact;
use Google::Devtools::Artifactregistry::V1::VpcscConfig;
use Google::Devtools::Artifactregistry::V1::AptArtifact;
use Google::Devtools::Artifactregistry::V1::Rule;
use Google::Devtools::Artifactregistry::V1::Repository;
use Google::Devtools::Artifactregistry::V1::Version;
use Google::Devtools::Artifactregistry::V1::Export;
use Google::Devtools::Artifactregistry::V1::Service;

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

    my $target = 'artifactregistry.googleapis.com:443';
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

sub list_docker_images {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.artifactregistry.v1.ArtifactRegistry/ListDockerImages',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.artifactregistry.v1.ArtifactRegistry',
        method         => 'ListDockerImages',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_project_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Artifactregistry::V1::Settings::UpdateProjectSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.artifactregistry.v1.ArtifactRegistry/UpdateProjectSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.artifactregistry.v1.ArtifactRegistry',
        method         => 'UpdateProjectSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Devtools::Artifactregistry::V1

__END__

=head1 NAME

Google::Cloud::Devtools::Artifactregistry::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Devtools::Artifactregistry::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Devtools::Artifactregistry::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Devtools::Artifactregistry::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Devtools::Artifactregistry::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/devtools/artifactregistry/v1/apt_artifact.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/artifact.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/attachment.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/export.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/file.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/generic.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/go.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/kfp_artifact.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/package.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/repository.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/rule.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/service.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/settings.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/tag.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/version.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/vpcsc_config.proto>

=item * C<googleapis/google/devtools/artifactregistry/v1/yum_artifact.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Devtools::Artifactregistry::V1->new(
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

=item * B<list_docker_images>

    my $response = $client->list_docker_images(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListDockerImages> on C<google.devtools.artifactregistry.v1.ArtifactRegistry>.

Request: L<Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest>

Returns: L<Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<update_project_settings>

    my $response = $client->update_project_settings(
        project_settings         => $project_settings,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateProjectSettings> on C<google.devtools.artifactregistry.v1.ArtifactRegistry>.

Request: L<Google::Devtools::Artifactregistry::V1::Settings::UpdateProjectSettingsRequest>

Returns: L<Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings>

Parameters:

=over 4

=item * C<project_settings> - L<Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
