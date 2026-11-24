package Google::Cloud::Securitycenter::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Securitycenter::V2::Chokepoint;
use Google::Cloud::Securitycenter::V2::Network;
use Google::Cloud::Securitycenter::V2::AgentSession;
use Google::Cloud::Securitycenter::V2::Agent;
use Google::Cloud::Securitycenter::V2::AiModel;
use Google::Cloud::Securitycenter::V2::AffectedResources;
use Google::Cloud::Securitycenter::V2::LoadBalancer;
use Google::Cloud::Securitycenter::V2::Compliance;
use Google::Cloud::Securitycenter::V2::ToxicCombination;
use Google::Cloud::Securitycenter::V2::SecurityPosture;
use Google::Cloud::Securitycenter::V2::Indicator;
use Google::Cloud::Securitycenter::V2::GroupMembership;
use Google::Cloud::Securitycenter::V2::Connection;
use Google::Cloud::Securitycenter::V2::MitreAttack;
use Google::Cloud::Securitycenter::V2::VertexAi;
use Google::Cloud::Securitycenter::V2::Folder;
use Google::Cloud::Securitycenter::V2::IamBinding;
use Google::Cloud::Securitycenter::V2::Exfiltration;
use Google::Cloud::Securitycenter::V2::AgentAnomaly;
use Google::Cloud::Securitycenter::V2::Access;
use Google::Cloud::Securitycenter::V2::Database;
use Google::Cloud::Securitycenter::V2::Application;
use Google::Cloud::Securitycenter::V2::File;
use Google::Cloud::Securitycenter::V2::KernelRootkit;
use Google::Cloud::Securitycenter::V2::Disk;
use Google::Cloud::Securitycenter::V2::ContactDetails;
use Google::Cloud::Securitycenter::V2::Label;
use Google::Cloud::Securitycenter::V2::IpRules;
use Google::Cloud::Securitycenter::V2::Job;
use Google::Cloud::Securitycenter::V2::DataAccessEvent;
use Google::Cloud::Securitycenter::V2::LogEntry;
use Google::Cloud::Securitycenter::V2::Notebook;
use Google::Cloud::Securitycenter::V2::Vulnerability;
use Google::Cloud::Securitycenter::V2::BackupDisasterRecovery;
use Google::Cloud::Securitycenter::V2::DataFlowEvent;
use Google::Cloud::Securitycenter::V2::AttackExposure;
use Google::Cloud::Securitycenter::V2::SecurityMarks;
use Google::Cloud::Securitycenter::V2::NotificationConfig;
use Google::Cloud::Securitycenter::V2::Resource;
use Google::Cloud::Securitycenter::V2::ValuedResource;
use Google::Cloud::Securitycenter::V2::MuteConfig;
use Google::Cloud::Securitycenter::V2::CloudDlpInspection;
use Google::Cloud::Securitycenter::V2::BigqueryExport;
use Google::Cloud::Securitycenter::V2::OrgPolicy;
use Google::Cloud::Securitycenter::V2::CloudDlpDataProfile;
use Google::Cloud::Securitycenter::V2::Source;
use Google::Cloud::Securitycenter::V2::ExternalSystem;
use Google::Cloud::Securitycenter::V2::AttackPath;
use Google::Cloud::Securitycenter::V2::Process;
use Google::Cloud::Securitycenter::V2::CloudArmor;
use Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent;
use Google::Cloud::Securitycenter::V2::Container;
use Google::Cloud::Securitycenter::V2::ResourceValueConfig;
use Google::Cloud::Securitycenter::V2::Simulation;
use Google::Cloud::Securitycenter::V2::Kubernetes;
use Google::Cloud::Securitycenter::V2::Finding;
use Google::Cloud::Securitycenter::V2::SecuritycenterService;
use Google::Cloud::Securitycenter::V2::NotificationMessage;

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

    my $target = 'securitycenter.googleapis.com:443';
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

sub batch_create_resource_value_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v2.SecurityCenter/BatchCreateResourceValueConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v2.SecurityCenter',
        method         => 'BatchCreateResourceValueConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_notification_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateNotificationConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v2.SecurityCenter/CreateNotificationConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v2.SecurityCenter',
        method         => 'CreateNotificationConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_notification_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v2.SecurityCenter/ListNotificationConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v2.SecurityCenter',
        method         => 'ListNotificationConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_source {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSourceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V2::Source::Source';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v2.SecurityCenter/UpdateSource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v2.SecurityCenter',
        method         => 'UpdateSource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Securitycenter::V2

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Securitycenter::V2->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Securitycenter::V2->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Securitycenter::V2> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/securitycenter/v2/access.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/affected_resources.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/agent.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/agent_anomaly.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/agent_session.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/ai_model.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/application.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/attack_exposure.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/attack_path.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/backup_disaster_recovery.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/bigquery_export.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/chokepoint.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/cloud_armor.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/cloud_dlp_data_profile.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/cloud_dlp_inspection.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/compliance.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/connection.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/contact_details.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/container.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/data_access_event.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/data_flow_event.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/data_retention_deletion_event.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/database.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/disk.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/exfiltration.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/external_system.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/file.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/finding.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/folder.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/group_membership.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/iam_binding.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/indicator.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/ip_rules.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/job.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/kernel_rootkit.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/kubernetes.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/label.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/load_balancer.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/log_entry.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/mitre_attack.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/mute_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/network.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/notebook.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/notification_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/notification_message.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/org_policy.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/process.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/resource.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/resource_value_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/security_marks.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/security_posture.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/securitycenter_service.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/simulation.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/source.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/toxic_combination.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/valued_resource.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/vertex_ai.proto>

=item * C<googleapis/google/cloud/securitycenter/v2/vulnerability.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Securitycenter::V2->new(
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

=item * B<batch_create_resource_value_configs>

    my $response = $client->batch_create_resource_value_configs(
        parent                   => $parent,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchCreateResourceValueConfigs> on C<google.cloud.securitycenter.v2.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsRequest>

Returns: L<Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<requests> - ArrayRef of L<Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateResourceValueConfigRequest>

=back

=item * B<create_notification_config>

    my $response = $client->create_notification_config(
        parent                   => $parent,
        config_id                => $config_id,
        notification_config      => $notification_config,
    );

Calls the RPC method C<CreateNotificationConfig> on C<google.cloud.securitycenter.v2.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateNotificationConfigRequest>

Returns: L<Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<config_id> - C<string>

=item * C<notification_config> - L<Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig>

=back

=item * B<list_notification_configs>

    my $response = $client->list_notification_configs(
        parent                   => $parent,
        page_token               => $page_token,
        page_size                => $page_size,
    );

Calls the RPC method C<ListNotificationConfigs> on C<google.cloud.securitycenter.v2.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsRequest>

Returns: L<Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=back

=item * B<update_source>

    my $response = $client->update_source(
        source                   => $source,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateSource> on C<google.cloud.securitycenter.v2.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSourceRequest>

Returns: L<Google::Cloud::Securitycenter::V2::Source::Source>

Parameters:

=over 4

=item * C<source> - L<Google::Cloud::Securitycenter::V2::Source::Source>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
