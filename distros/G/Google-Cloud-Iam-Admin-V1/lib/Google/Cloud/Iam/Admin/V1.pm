package Google::Cloud::Iam::Admin::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Iam::Admin::V1::WorkforcePoolPlatformLogs;
use Google::Iam::Admin::V1::AuditData;
use Google::Iam::Admin::V1::Iam;

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

    my $target = 'iam.googleapis.com:443';
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

sub list_service_accounts {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::Admin::V1::Iam::ListServiceAccountsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.iam.admin.v1.IAM/ListServiceAccounts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.iam.admin.v1.IAM',
        method         => 'ListServiceAccounts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query_testable_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.iam.admin.v1.IAM/QueryTestablePermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.iam.admin.v1.IAM',
        method         => 'QueryTestablePermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query_auditable_services {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.iam.admin.v1.IAM/QueryAuditableServices',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.iam.admin.v1.IAM',
        method         => 'QueryAuditableServices',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub lint_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::Admin::V1::Iam::LintPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::Admin::V1::Iam::LintPolicyResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.iam.admin.v1.IAM/LintPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.iam.admin.v1.IAM',
        method         => 'LintPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Iam::Admin::V1

__END__

=head1 NAME

Google::Cloud::Iam::Admin::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Iam::Admin::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Iam::Admin::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Iam::Admin::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Iam::Admin::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/iam/admin/v1/audit_data.proto>

=item * C<googleapis/google/iam/admin/v1/iam.proto>

=item * C<googleapis/google/iam/admin/v1/workforce_pool_platform_logs.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Iam::Admin::V1->new(
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

=item * B<list_service_accounts>

    my $response = $client->list_service_accounts(
        name                     => $name,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListServiceAccounts> on C<google.iam.admin.v1.IAM>.

Request: L<Google::Iam::Admin::V1::Iam::ListServiceAccountsRequest>

Returns: L<Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<query_testable_permissions>

    my $response = $client->query_testable_permissions(
        full_resource_name       => $full_resource_name,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<QueryTestablePermissions> on C<google.iam.admin.v1.IAM>.

Request: L<Google::Iam::Admin::V1::Iam::QueryTestablePermissionsRequest>

Returns: L<Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse>

Parameters:

=over 4

=item * C<full_resource_name> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<query_auditable_services>

    my $response = $client->query_auditable_services(
        full_resource_name       => $full_resource_name,
    );

Calls the RPC method C<QueryAuditableServices> on C<google.iam.admin.v1.IAM>.

Request: L<Google::Iam::Admin::V1::Iam::QueryAuditableServicesRequest>

Returns: L<Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse>

Parameters:

=over 4

=item * C<full_resource_name> - C<string>

=back

=item * B<lint_policy>

    my $response = $client->lint_policy(
        full_resource_name       => $full_resource_name,
    );

Calls the RPC method C<LintPolicy> on C<google.iam.admin.v1.IAM>.

Request: L<Google::Iam::Admin::V1::Iam::LintPolicyRequest>

Returns: L<Google::Iam::Admin::V1::Iam::LintPolicyResponse>

Parameters:

=over 4

=item * C<full_resource_name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
