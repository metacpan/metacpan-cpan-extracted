package Google::Cloud::Gkebackup::V1::BackupForGKEClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Gkebackup::V1::RestorePlanBinding;
use Google::Cloud::Gkebackup::V1::Common;
use Google::Cloud::Gkebackup::V1::RestoreChannel;
use Google::Cloud::Gkebackup::V1::BackupChannel;
use Google::Cloud::Gkebackup::V1::BackupPlan;
use Google::Cloud::Gkebackup::V1::BackupPlanBinding;
use Google::Cloud::Gkebackup::V1::Backup;
use Google::Cloud::Gkebackup::V1::Volume;
use Google::Cloud::Gkebackup::V1::Restore;
use Google::Cloud::Gkebackup::V1::RestorePlan;
use Google::Cloud::Gkebackup::V1::Gkebackup;

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

    my $target = 'gkebackup.googleapis.com:443';
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

sub create_backup_plan {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupPlanRequest';
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
            path           => '/google.cloud.gkebackup.v1.BackupForGKE/CreateBackupPlan',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkebackup.v1.BackupForGKE',
        method         => 'CreateBackupPlan',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Gkebackup::V1::BackupForGKEClient

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::BackupForGKEClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::BackupForGKEClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Gkebackup::V1::BackupForGKEClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Gkebackup::V1::BackupForGKEClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Gkebackup::V1::BackupForGKEClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/gkebackup/v1/backup.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/backup_channel.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/backup_plan.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/backup_plan_binding.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/common.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/gkebackup.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/restore.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/restore_channel.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/restore_plan.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/restore_plan_binding.proto>

=item * C<googleapis/google/cloud/gkebackup/v1/volume.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Gkebackup::V1::BackupForGKEClient->new(
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

=item * B<create_backup_plan>

    my $response = $client->create_backup_plan(
        parent                   => $parent,
        backup_plan              => $backup_plan,
        backup_plan_id           => $backup_plan_id,
    );

Calls the RPC method C<CreateBackupPlan> on C<google.cloud.gkebackup.v1.BackupForGKE>.

Request: L<Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupPlanRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<backup_plan> - L<Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan>

=item * C<backup_plan_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
