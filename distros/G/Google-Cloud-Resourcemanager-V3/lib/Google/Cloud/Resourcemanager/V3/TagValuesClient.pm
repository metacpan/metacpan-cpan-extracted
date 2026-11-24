package Google::Cloud::Resourcemanager::V3::TagValuesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Resourcemanager::V3::Organizations;
use Google::Cloud::Resourcemanager::V3::TagKeys;
use Google::Cloud::Resourcemanager::V3::Folders;
use Google::Cloud::Resourcemanager::V3::Projects;
use Google::Cloud::Resourcemanager::V3::TagBindings;
use Google::Cloud::Resourcemanager::V3::TagValues;
use Google::Cloud::Resourcemanager::V3::TagHolds;

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

sub list_tag_values {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagValues/ListTagValues',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'ListTagValues',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagValues/GetTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'GetTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_namespaced_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagValues/GetNamespacedTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'GetNamespacedTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/CreateTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'CreateTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/UpdateTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'UpdateTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/DeleteTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'DeleteTagValue',
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Resourcemanager::V3::TagValuesClient

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagValuesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::TagValuesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Resourcemanager::V3::TagValuesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Resourcemanager::V3::TagValuesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Resourcemanager::V3::TagValuesClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Resourcemanager::V3::TagValuesClient->new(
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

=item * B<list_tag_values>

    my $response = $client->list_tag_values(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTagValues> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_tag_value>

    my $response = $client->get_tag_value(
        name                     => $name,
    );

Calls the RPC method C<GetTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_namespaced_tag_value>

    my $response = $client->get_namespaced_tag_value(
        name                     => $name,
    );

Calls the RPC method C<GetNamespacedTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_tag_value>

    my $response = $client->create_tag_value(
        tag_value                => $tag_value,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_value> - L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

=item * C<validate_only> - C<bool>

=back

=item * B<update_tag_value>

    my $response = $client->update_tag_value(
        tag_value                => $tag_value,
        update_mask              => $update_mask,
        validate_only            => $validate_only,
    );

Calls the RPC method C<UpdateTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_value> - L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<validate_only> - C<bool>

=back

=item * B<delete_tag_value>

    my $response = $client->delete_tag_value(
        name                     => $name,
        validate_only            => $validate_only,
        etag                     => $etag,
    );

Calls the RPC method C<DeleteTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<validate_only> - C<bool>

=item * C<etag> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy();

Calls the RPC method C<GetIamPolicy> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Iam::V1::IamPolicy::GetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy();

Calls the RPC method C<SetIamPolicy> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Iam::V1::IamPolicy::SetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions();

Calls the RPC method C<TestIamPermissions> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Iam::V1::IamPolicy::TestIamPermissionsRequest>

Returns: L<Google::Iam::V1::IamPolicy::TestIamPermissionsResponse>

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
