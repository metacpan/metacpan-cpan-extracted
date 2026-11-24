package Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Contentwarehouse::V1::Histogram;
use Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest;
use Google::Cloud::Contentwarehouse::V1::DocumentSchema;
use Google::Cloud::Contentwarehouse::V1::Synonymset;
use Google::Cloud::Contentwarehouse::V1::RuleEngine;
use Google::Cloud::Contentwarehouse::V1::Common;
use Google::Cloud::Contentwarehouse::V1::Filters;
use Google::Cloud::Contentwarehouse::V1::Document;
use Google::Cloud::Contentwarehouse::V1::DocumentSchemaService;
use Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest;
use Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest;
use Google::Cloud::Contentwarehouse::V1::Pipelines;
use Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest;
use Google::Cloud::Contentwarehouse::V1::DocumentLinkService;
use Google::Cloud::Contentwarehouse::V1::SynonymsetService;
use Google::Cloud::Contentwarehouse::V1::RulesetService;
use Google::Cloud::Contentwarehouse::V1::PipelineService;
use Google::Cloud::Contentwarehouse::V1::DocumentService;

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

    my $target = 'contentwarehouse.googleapis.com:443';
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

sub list_linked_targets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.contentwarehouse.v1.DocumentLinkService/ListLinkedTargets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentLinkService',
        method         => 'ListLinkedTargets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/contentwarehouse/v1/async_document_service_request.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/common.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/document.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/document_link_service.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/document_schema.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/document_schema_service.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/document_service.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/document_service_request.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/filters.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/histogram.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/pipeline_service.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/pipelines.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/rule_engine.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/ruleset_service.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/ruleset_service_request.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/synonymset.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/synonymset_service.proto>

=item * C<googleapis/google/cloud/contentwarehouse/v1/synonymset_service_request.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient->new(
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

=item * B<list_linked_targets>

    my $response = $client->list_linked_targets(
        parent                   => $parent,
        request_metadata         => $request_metadata,
    );

Calls the RPC method C<ListLinkedTargets> on C<google.cloud.contentwarehouse.v1.DocumentLinkService>.

Request: L<Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest>

Returns: L<Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<request_metadata> - L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
