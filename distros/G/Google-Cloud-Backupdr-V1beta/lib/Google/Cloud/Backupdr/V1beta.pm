package Google::Cloud::Backupdr::V1beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Backupdr::V1beta::BackupvaultBa;
use Google::Cloud::Backupdr::V1beta::BackupvaultGce;
use Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb;
use Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan;
use Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding;
use Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon;
use Google::Cloud::Backupdr::V1beta::ProtectionSummary;
use Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql;
use Google::Cloud::Backupdr::V1beta::Bindingmatchingresource;
use Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation;
use Google::Cloud::Backupdr::V1beta::Backupplan;
use Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy;
use Google::Cloud::Backupdr::V1beta::BackupvaultDisk;
use Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution;
use Google::Cloud::Backupdr::V1beta::Backupplanassociation;
use Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy;
use Google::Cloud::Backupdr::V1beta::Backupvault;
use Google::Cloud::Backupdr::V1beta::RestoreTemplate;
use Google::Cloud::Backupdr::V1beta::Datasourcereference;
use Google::Cloud::Backupdr::V1beta::Backupdr;

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

    my $target = 'backupdr.googleapis.com:443';
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

sub list_management_servers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.backupdr.v1beta.BackupDR/ListManagementServers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.backupdr.v1beta.BackupDR',
        method         => 'ListManagementServers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_resource_backup_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.backupdr.v1beta.BackupDrProtectionSummary/ListResourceBackupConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.backupdr.v1beta.BackupDrProtectionSummary',
        method         => 'ListResourceBackupConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Backupdr::V1beta

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Backupdr::V1beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Backupdr::V1beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Backupdr::V1beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/backupdr/v1beta/appliedautoprotectionpolicy.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/autoprotectionpolicy.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/autoprotectionpolicybinding.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupdr.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupplan.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupplanassociation.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupvault.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupvault_alloydb.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupvault_ba.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupvault_cloudsql.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupvault_disk.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/backupvault_gce.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/bindingmatchingresource.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/datasourcereference.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/protection_summary.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/restore_template.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/restore_template_common.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/restore_template_execution.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/restore_verification_plan.proto>

=item * C<googleapis/google/cloud/backupdr/v1beta/restore_verification_plan_association.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Backupdr::V1beta->new(
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

=item * B<list_management_servers>

    my $response = $client->list_management_servers(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListManagementServers> on C<google.cloud.backupdr.v1beta.BackupDR>.

Request: L<Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersRequest>

Returns: L<Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<list_resource_backup_configs>

    my $response = $client->list_resource_backup_configs(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListResourceBackupConfigs> on C<google.cloud.backupdr.v1beta.BackupDrProtectionSummary>.

Request: L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest>

Returns: L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
