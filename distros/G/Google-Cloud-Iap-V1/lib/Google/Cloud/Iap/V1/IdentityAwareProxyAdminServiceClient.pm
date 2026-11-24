package Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Iap::V1::Service;

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

    my $target = 'iap.googleapis.com:443';
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
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'SetIamPolicy',
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
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'GetIamPolicy',
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
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iap_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Iap::V1::Service::GetIapSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Iap::V1::Service::IapSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/GetIapSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'GetIapSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_iap_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Iap::V1::Service::UpdateIapSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Iap::V1::Service::IapSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/UpdateIapSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'UpdateIapSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub validate_iap_attribute_expression {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/ValidateIapAttributeExpression',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'ValidateIapAttributeExpression',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tunnel_dest_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.iap.v1.IdentityAwareProxyAdminService/ListTunnelDestGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.iap.v1.IdentityAwareProxyAdminService',
        method         => 'ListTunnelDestGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient

__END__

=head1 NAME

Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/iap/v1/service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient->new(
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

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy();

Calls the RPC method C<SetIamPolicy> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Iam::V1::IamPolicy::SetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy();

Calls the RPC method C<GetIamPolicy> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Iam::V1::IamPolicy::GetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions();

Calls the RPC method C<TestIamPermissions> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Iam::V1::IamPolicy::TestIamPermissionsRequest>

Returns: L<Google::Iam::V1::IamPolicy::TestIamPermissionsResponse>

=item * B<get_iap_settings>

    my $response = $client->get_iap_settings(
        name                     => $name,
    );

Calls the RPC method C<GetIapSettings> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Cloud::Iap::V1::Service::GetIapSettingsRequest>

Returns: L<Google::Cloud::Iap::V1::Service::IapSettings>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_iap_settings>

    my $response = $client->update_iap_settings(
        iap_settings             => $iap_settings,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateIapSettings> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Cloud::Iap::V1::Service::UpdateIapSettingsRequest>

Returns: L<Google::Cloud::Iap::V1::Service::IapSettings>

Parameters:

=over 4

=item * C<iap_settings> - L<Google::Cloud::Iap::V1::Service::IapSettings>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<validate_iap_attribute_expression>

    my $response = $client->validate_iap_attribute_expression(
        name                     => $name,
        expression               => $expression,
    );

Calls the RPC method C<ValidateIapAttributeExpression> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionRequest>

Returns: L<Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<expression> - C<string>

=back

=item * B<list_tunnel_dest_groups>

    my $response = $client->list_tunnel_dest_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTunnelDestGroups> on C<google.cloud.iap.v1.IdentityAwareProxyAdminService>.

Request: L<Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsRequest>

Returns: L<Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse>

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
