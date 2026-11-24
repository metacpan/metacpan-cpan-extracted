package Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Bigquery::Migration::V2::TranslationConfig;
use Google::Cloud::Bigquery::Migration::V2::AssessmentTask;
use Google::Cloud::Bigquery::Migration::V2::TranslationDetails;
use Google::Cloud::Bigquery::Migration::V2::TranslationUsability;
use Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion;
use Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails;
use Google::Cloud::Bigquery::Migration::V2::MigrationMetrics;
use Google::Cloud::Bigquery::Migration::V2::MigrationEntities;
use Google::Cloud::Bigquery::Migration::V2::MigrationService;

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

    my $target = 'bigquerymigration.googleapis.com:443';
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

sub create_migration_workflow {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.migration.v2.MigrationService/CreateMigrationWorkflow',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'CreateMigrationWorkflow',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/bigquery/migration/v2/assessment_task.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/migration_entities.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/migration_error_details.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/migration_metrics.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/migration_service.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/translation_config.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/translation_details.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/translation_suggestion.proto>

=item * C<googleapis/google/cloud/bigquery/migration/v2/translation_usability.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigquery::Migration::V2::MigrationServiceClient->new(
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

=item * B<create_migration_workflow>

    my $response = $client->create_migration_workflow(
        parent                   => $parent,
        migration_workflow       => $migration_workflow,
    );

Calls the RPC method C<CreateMigrationWorkflow> on C<google.cloud.bigquery.migration.v2.MigrationService>.

Request: L<Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest>

Returns: L<Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<migration_workflow> - L<Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
