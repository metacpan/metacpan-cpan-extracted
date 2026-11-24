package Google::Cloud::Datacatalog::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Datacatalog::V1::PhysicalSchema;
use Google::Cloud::Datacatalog::V1::Bigquery;
use Google::Cloud::Datacatalog::V1::DataSource;
use Google::Cloud::Datacatalog::V1::Schema;
use Google::Cloud::Datacatalog::V1::Usage;
use Google::Cloud::Datacatalog::V1::Common;
use Google::Cloud::Datacatalog::V1::Timestamps;
use Google::Cloud::Datacatalog::V1::Tags;
use Google::Cloud::Datacatalog::V1::TableSpec;
use Google::Cloud::Datacatalog::V1::Search;
use Google::Cloud::Datacatalog::V1::DataplexSpec;
use Google::Cloud::Datacatalog::V1::Policytagmanager;
use Google::Cloud::Datacatalog::V1::GcsFilesetSpec;
use Google::Cloud::Datacatalog::V1::Policytagmanagerserialization;
use Google::Cloud::Datacatalog::V1::Datacatalog;
use Google::Cloud::Datacatalog::V1::DumpContent;

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

    my $target = 'datacatalog.googleapis.com:443';
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

sub search_catalog {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.datacatalog.v1.DataCatalog/SearchCatalog',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.datacatalog.v1.DataCatalog',
        method         => 'SearchCatalog',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_entry_group {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryGroupRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Datacatalog::V1::Datacatalog::EntryGroup';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.datacatalog.v1.DataCatalog/CreateEntryGroup',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.datacatalog.v1.DataCatalog',
        method         => 'CreateEntryGroup',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_taxonomy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.datacatalog.v1.PolicyTagManager/CreateTaxonomy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'CreateTaxonomy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub replace_taxonomy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ReplaceTaxonomyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.datacatalog.v1.PolicyTagManagerSerialization/ReplaceTaxonomy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManagerSerialization',
        method         => 'ReplaceTaxonomy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Datacatalog::V1

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Datacatalog::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Datacatalog::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Datacatalog::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/datacatalog/v1/bigquery.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/common.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/data_source.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/datacatalog.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/dataplex_spec.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/dump_content.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/gcs_fileset_spec.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/physical_schema.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/policytagmanager.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/policytagmanagerserialization.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/schema.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/search.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/table_spec.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/tags.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/timestamps.proto>

=item * C<googleapis/google/cloud/datacatalog/v1/usage.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Datacatalog::V1->new(
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

=item * B<search_catalog>

    my $response = $client->search_catalog(
        scope                    => $scope,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
        order_by                 => $order_by,
        admin_search             => $admin_search,
    );

Calls the RPC method C<SearchCatalog> on C<google.cloud.datacatalog.v1.DataCatalog>.

Request: L<Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest>

Returns: L<Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogResponse>

Parameters:

=over 4

=item * C<scope> - L<Google::Cloud::Datacatalog::V1::Datacatalog::Scope>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<order_by> - C<string>

=item * C<admin_search> - C<bool>

=back

=item * B<create_entry_group>

    my $response = $client->create_entry_group(
        parent                   => $parent,
        entry_group_id           => $entry_group_id,
        entry_group              => $entry_group,
    );

Calls the RPC method C<CreateEntryGroup> on C<google.cloud.datacatalog.v1.DataCatalog>.

Request: L<Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryGroupRequest>

Returns: L<Google::Cloud::Datacatalog::V1::Datacatalog::EntryGroup>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<entry_group_id> - C<string>

=item * C<entry_group> - L<Google::Cloud::Datacatalog::V1::Datacatalog::EntryGroup>

=back

=item * B<create_taxonomy>

    my $response = $client->create_taxonomy(
        parent                   => $parent,
        taxonomy                 => $taxonomy,
    );

Calls the RPC method C<CreateTaxonomy> on C<google.cloud.datacatalog.v1.PolicyTagManager>.

Request: L<Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest>

Returns: L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<taxonomy> - L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>

=back

=item * B<replace_taxonomy>

    my $response = $client->replace_taxonomy(
        name                     => $name,
        serialized_taxonomy      => $serialized_taxonomy,
    );

Calls the RPC method C<ReplaceTaxonomy> on C<google.cloud.datacatalog.v1.PolicyTagManagerSerialization>.

Request: L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ReplaceTaxonomyRequest>

Returns: L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<serialized_taxonomy> - L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
