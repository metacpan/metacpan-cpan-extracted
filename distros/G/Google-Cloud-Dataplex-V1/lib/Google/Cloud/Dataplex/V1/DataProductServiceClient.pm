package Google::Cloud::Dataplex::V1::DataProductServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dataplex::V1::DataQualityRuleTemplate;
use Google::Cloud::Dataplex::V1::DatascansCommon;
use Google::Cloud::Dataplex::V1::Security;
use Google::Cloud::Dataplex::V1::DataDiscovery;
use Google::Cloud::Dataplex::V1::DataDocumentation;
use Google::Cloud::Dataplex::V1::Processing;
use Google::Cloud::Dataplex::V1::Content;
use Google::Cloud::Dataplex::V1::Resources;
use Google::Cloud::Dataplex::V1::Metadata;
use Google::Cloud::Dataplex::V1::Logs;
use Google::Cloud::Dataplex::V1::DataProfile;
use Google::Cloud::Dataplex::V1::DataQuality;
use Google::Cloud::Dataplex::V1::Tasks;
use Google::Cloud::Dataplex::V1::Analyze;
use Google::Cloud::Dataplex::V1::Service;
use Google::Cloud::Dataplex::V1::Catalog;
use Google::Cloud::Dataplex::V1::DataTaxonomy;
use Google::Cloud::Dataplex::V1::Datascans;
use Google::Cloud::Dataplex::V1::BusinessGlossary;
use Google::Cloud::Dataplex::V1::Cmek;
use Google::Cloud::Dataplex::V1::ApprovalWorkflow;
use Google::Cloud::Dataplex::V1::DataProducts;

our $VERSION = '0.05';

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

    my $target = 'dataplex.googleapis.com:443';
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

sub create_data_product {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataplex::V1::DataProducts::CreateDataProductRequest';
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
            path           => '/google.cloud.dataplex.v1.DataProductService/CreateDataProduct',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataplex.v1.DataProductService',
        method         => 'CreateDataProduct',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dataplex::V1::DataProductServiceClient

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataProductServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::DataProductServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dataplex::V1::DataProductServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dataplex::V1::DataProductServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dataplex::V1::DataProductServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dataplex/v1/analyze.proto>

=item * C<googleapis/google/cloud/dataplex/v1/approval_workflow.proto>

=item * C<googleapis/google/cloud/dataplex/v1/business_glossary.proto>

=item * C<googleapis/google/cloud/dataplex/v1/catalog.proto>

=item * C<googleapis/google/cloud/dataplex/v1/cmek.proto>

=item * C<googleapis/google/cloud/dataplex/v1/content.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_discovery.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_documentation.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_products.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_profile.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_quality.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_quality_rule_template.proto>

=item * C<googleapis/google/cloud/dataplex/v1/datascans_common.proto>

=item * C<googleapis/google/cloud/dataplex/v1/datascans.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_taxonomy.proto>

=item * C<googleapis/google/cloud/dataplex/v1/logs.proto>

=item * C<googleapis/google/cloud/dataplex/v1/metadata.proto>

=item * C<googleapis/google/cloud/dataplex/v1/processing.proto>

=item * C<googleapis/google/cloud/dataplex/v1/resources.proto>

=item * C<googleapis/google/cloud/dataplex/v1/security.proto>

=item * C<googleapis/google/cloud/dataplex/v1/service.proto>

=item * C<googleapis/google/cloud/dataplex/v1/tasks.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dataplex::V1::DataProductServiceClient->new(
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

=item * B<create_data_product>

Calls the RPC method C<CreateDataProduct> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
