package Google::Cloud::Resourcemanager::V3::OrganizationsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Resourcemanager::V3::TagHolds;
use Google::Cloud::Resourcemanager::V3::TagBindings;
use Google::Cloud::Resourcemanager::V3::Organizations;
use Google::Cloud::Resourcemanager::V3::TagKeys;
use Google::Cloud::Resourcemanager::V3::TagValues;
use Google::Cloud::Resourcemanager::V3::Folders;
use Google::Cloud::Resourcemanager::V3::Projects;

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

    my $target = 'cloudresourcemanager.googleapis.com:443';
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

sub get_organization {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Organizations::Organization';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/GetOrganization',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'GetOrganization',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_organizations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/SearchOrganizations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'SearchOrganizations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Resourcemanager::V3::OrganizationsClient

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::OrganizationsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::OrganizationsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Resourcemanager::V3::OrganizationsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Resourcemanager::V3::OrganizationsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Resourcemanager::V3::OrganizationsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/resourcemanager/v3/folders.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/organizations.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/projects.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_bindings.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_holds.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_keys.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_values.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Resourcemanager::V3::OrganizationsClient->new(
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

=item * B<get_organization>

    my $response = $client->get_organization(
        name                     => $name,
    );

Calls the RPC method C<GetOrganization> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Organizations::Organization>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search_organizations>

    my $response = $client->search_organizations(
        page_size                => $page_size,
        page_token               => $page_token,
        query                    => $query,
    );

Calls the RPC method C<SearchOrganizations> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<query> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy();

Calls the RPC method C<GetIamPolicy> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Iam::V1::IamPolicy::GetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy();

Calls the RPC method C<SetIamPolicy> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Iam::V1::IamPolicy::SetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions();

Calls the RPC method C<TestIamPermissions> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Iam::V1::IamPolicy::TestIamPermissionsRequest>

Returns: L<Google::Iam::V1::IamPolicy::TestIamPermissionsResponse>

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
