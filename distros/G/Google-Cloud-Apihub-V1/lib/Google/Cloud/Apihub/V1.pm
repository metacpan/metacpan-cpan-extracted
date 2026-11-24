package Google::Cloud::Apihub::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Apihub::V1::CommonFields;
use Google::Cloud::Apihub::V1::CurateService;
use Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService;
use Google::Cloud::Apihub::V1::HostProjectRegistrationService;
use Google::Cloud::Apihub::V1::DiscoveryService;
use Google::Cloud::Apihub::V1::CollectService;
use Google::Cloud::Apihub::V1::PluginService;
use Google::Cloud::Apihub::V1::ProvisioningService;
use Google::Cloud::Apihub::V1::ApihubService;
use Google::Cloud::Apihub::V1::LintingService;

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

    my $target = 'apihub.googleapis.com:443';
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

sub create_api {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::ApihubService::CreateApiRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::CommonFields::Api';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.ApiHub/CreateApi',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.ApiHub',
        method         => 'CreateApi',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub collect_api_data {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest';
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
            path           => '/google.cloud.apihub.v1.ApiHubCollect/CollectApiData',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.ApiHubCollect',
        method         => 'CollectApiData',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_curation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::CurateService::Curation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.ApiHubCurate/CreateCuration',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.ApiHubCurate',
        method         => 'CreateCuration',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_discovered_api_observations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.ApiHubDiscovery/ListDiscoveredApiObservations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.ApiHubDiscovery',
        method         => 'ListDiscoveredApiObservations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_host_project_registration {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.HostProjectRegistrationService/CreateHostProjectRegistration',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.HostProjectRegistrationService',
        method         => 'CreateHostProjectRegistration',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_style_guide {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::LintingService::StyleGuide';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.LintingService/GetStyleGuide',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.LintingService',
        method         => 'GetStyleGuide',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_style_guide_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::LintingService::StyleGuideContents';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.LintingService/GetStyleGuideContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.LintingService',
        method         => 'GetStyleGuideContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_plugin {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::PluginService::GetPluginRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::PluginService::Plugin';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.ApiHubPlugin/GetPlugin',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.ApiHubPlugin',
        method         => 'GetPlugin',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_api_hub_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest';
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
            path           => '/google.cloud.apihub.v1.Provisioning/CreateApiHubInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.Provisioning',
        method         => 'CreateApiHubInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_runtime_project_attachment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.RuntimeProjectAttachmentService/CreateRuntimeProjectAttachment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.RuntimeProjectAttachmentService',
        method         => 'CreateRuntimeProjectAttachment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Apihub::V1

__END__

=head1 NAME

Google::Cloud::Apihub::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Apihub::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Apihub::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Apihub::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/apihub/v1/apihub_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/collect_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/common_fields.proto>

=item * C<googleapis/google/cloud/apihub/v1/curate_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/discovery_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/host_project_registration_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/linting_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/plugin_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/provisioning_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/runtime_project_attachment_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Apihub::V1->new(
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

=item * B<create_api>

    my $response = $client->create_api(
        parent                   => $parent,
        api_id                   => $api_id,
        api                      => $api,
    );

Calls the RPC method C<CreateApi> on C<google.cloud.apihub.v1.ApiHub>.

Request: L<Google::Cloud::Apihub::V1::ApihubService::CreateApiRequest>

Returns: L<Google::Cloud::Apihub::V1::CommonFields::Api>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<api_id> - C<string>

=item * C<api> - L<Google::Cloud::Apihub::V1::CommonFields::Api>

=back

=item * B<collect_api_data>

    my $response = $client->collect_api_data(
        location                 => $location,
        collection_type          => $collection_type,
        plugin_instance          => $plugin_instance,
        action_id                => $action_id,
        api_data                 => $api_data,
    );

Calls the RPC method C<CollectApiData> on C<google.cloud.apihub.v1.ApiHubCollect>.

Request: L<Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<location> - C<string>

=item * C<collection_type> - L<Google::Cloud::Apihub::V1::CollectService::CollectionType>

=item * C<plugin_instance> - C<string>

=item * C<action_id> - C<string>

=item * C<api_data> - L<Google::Cloud::Apihub::V1::CollectService::ApiData>

=back

=item * B<create_curation>

    my $response = $client->create_curation(
        parent                   => $parent,
        curation_id              => $curation_id,
        curation                 => $curation,
    );

Calls the RPC method C<CreateCuration> on C<google.cloud.apihub.v1.ApiHubCurate>.

Request: L<Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest>

Returns: L<Google::Cloud::Apihub::V1::CurateService::Curation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<curation_id> - C<string>

=item * C<curation> - L<Google::Cloud::Apihub::V1::CurateService::Curation>

=back

=item * B<list_discovered_api_observations>

    my $response = $client->list_discovered_api_observations(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListDiscoveredApiObservations> on C<google.cloud.apihub.v1.ApiHubDiscovery>.

Request: L<Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest>

Returns: L<Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_host_project_registration>

    my $response = $client->create_host_project_registration(
        parent                   => $parent,
        host_project_registration_id => $host_project_registration_id,
        host_project_registration => $host_project_registration,
    );

Calls the RPC method C<CreateHostProjectRegistration> on C<google.cloud.apihub.v1.HostProjectRegistrationService>.

Request: L<Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest>

Returns: L<Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<host_project_registration_id> - C<string>

=item * C<host_project_registration> - L<Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration>

=back

=item * B<get_style_guide>

    my $response = $client->get_style_guide(
        name                     => $name,
    );

Calls the RPC method C<GetStyleGuide> on C<google.cloud.apihub.v1.LintingService>.

Request: L<Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest>

Returns: L<Google::Cloud::Apihub::V1::LintingService::StyleGuide>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_style_guide_contents>

    my $response = $client->get_style_guide_contents(
        name                     => $name,
    );

Calls the RPC method C<GetStyleGuideContents> on C<google.cloud.apihub.v1.LintingService>.

Request: L<Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest>

Returns: L<Google::Cloud::Apihub::V1::LintingService::StyleGuideContents>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_plugin>

    my $response = $client->get_plugin(
        name                     => $name,
    );

Calls the RPC method C<GetPlugin> on C<google.cloud.apihub.v1.ApiHubPlugin>.

Request: L<Google::Cloud::Apihub::V1::PluginService::GetPluginRequest>

Returns: L<Google::Cloud::Apihub::V1::PluginService::Plugin>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_api_hub_instance>

    my $response = $client->create_api_hub_instance(
        parent                   => $parent,
        api_hub_instance_id      => $api_hub_instance_id,
        api_hub_instance         => $api_hub_instance,
    );

Calls the RPC method C<CreateApiHubInstance> on C<google.cloud.apihub.v1.Provisioning>.

Request: L<Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<api_hub_instance_id> - C<string>

=item * C<api_hub_instance> - L<Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance>

=back

=item * B<create_runtime_project_attachment>

    my $response = $client->create_runtime_project_attachment(
        parent                   => $parent,
        runtime_project_attachment_id => $runtime_project_attachment_id,
        runtime_project_attachment => $runtime_project_attachment,
    );

Calls the RPC method C<CreateRuntimeProjectAttachment> on C<google.cloud.apihub.v1.RuntimeProjectAttachmentService>.

Request: L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest>

Returns: L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<runtime_project_attachment_id> - C<string>

=item * C<runtime_project_attachment> - L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
