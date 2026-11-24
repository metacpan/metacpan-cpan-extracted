package Google::Cloud::Securitycenter::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Securitycenter::V1::ToxicCombination;
use Google::Cloud::Securitycenter::V1::LoadBalancer;
use Google::Cloud::Securitycenter::V1::SecurityPosture;
use Google::Cloud::Securitycenter::V1::Connection;
use Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors;
use Google::Cloud::Securitycenter::V1::ContactDetails;
use Google::Cloud::Securitycenter::V1::Indicator;
use Google::Cloud::Securitycenter::V1::AgentAnomaly;
use Google::Cloud::Securitycenter::V1::IamBinding;
use Google::Cloud::Securitycenter::V1::Exfiltration;
use Google::Cloud::Securitycenter::V1::Access;
use Google::Cloud::Securitycenter::V1::Label;
use Google::Cloud::Securitycenter::V1::AgentSession;
use Google::Cloud::Securitycenter::V1::Folder;
use Google::Cloud::Securitycenter::V1::File;
use Google::Cloud::Securitycenter::V1::KernelRootkit;
use Google::Cloud::Securitycenter::V1::MitreAttack;
use Google::Cloud::Securitycenter::V1::GroupMembership;
use Google::Cloud::Securitycenter::V1::Database;
use Google::Cloud::Securitycenter::V1::Agent;
use Google::Cloud::Securitycenter::V1::Application;
use Google::Cloud::Securitycenter::V1::Compliance;
use Google::Cloud::Securitycenter::V1::Chokepoint;
use Google::Cloud::Securitycenter::V1::Process;
use Google::Cloud::Securitycenter::V1::ValuedResource;
use Google::Cloud::Securitycenter::V1::CloudDlpInspection;
use Google::Cloud::Securitycenter::V1::CloudDlpDataProfile;
use Google::Cloud::Securitycenter::V1::AttackPath;
use Google::Cloud::Securitycenter::V1::Resource;
use Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule;
use Google::Cloud::Securitycenter::V1::NotificationConfig;
use Google::Cloud::Securitycenter::V1::SecurityMarks;
use Google::Cloud::Securitycenter::V1::OrganizationSettings;
use Google::Cloud::Securitycenter::V1::Source;
use Google::Cloud::Securitycenter::V1::OrgPolicy;
use Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse;
use Google::Cloud::Securitycenter::V1::CloudArmor;
use Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig;
use Google::Cloud::Securitycenter::V1::Notebook;
use Google::Cloud::Securitycenter::V1::LogEntry;
use Google::Cloud::Securitycenter::V1::MuteConfig;
use Google::Cloud::Securitycenter::V1::AttackExposure;
use Google::Cloud::Securitycenter::V1::ExternalSystem;
use Google::Cloud::Securitycenter::V1::BigqueryExport;
use Google::Cloud::Securitycenter::V1::BackupDisasterRecovery;
use Google::Cloud::Securitycenter::V1::Vulnerability;
use Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule;
use Google::Cloud::Securitycenter::V1::Container;
use Google::Cloud::Securitycenter::V1::ExternalExposure;
use Google::Cloud::Securitycenter::V1::ResourceValueConfig;
use Google::Cloud::Securitycenter::V1::Simulation;
use Google::Cloud::Securitycenter::V1::Asset;
use Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule;
use Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule;
use Google::Cloud::Securitycenter::V1::Kubernetes;
use Google::Cloud::Securitycenter::V1::Finding;
use Google::Cloud::Securitycenter::V1::SecuritycenterService;
use Google::Cloud::Securitycenter::V1::NotificationMessage;

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

sub bulk_mute_findings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsRequest';
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
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/BulkMuteFindings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'BulkMuteFindings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_source {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSourceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::Source::Source';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/CreateSource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'CreateSource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_security_health_analytics_custom_module {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/GetEffectiveSecurityHealthAnalyticsCustomModule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'GetEffectiveSecurityHealthAnalyticsCustomModule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_findings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/ListFindings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'ListFindings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_security_health_analytics_custom_modules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/ListSecurityHealthAnalyticsCustomModules',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'ListSecurityHealthAnalyticsCustomModules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_external_system {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateExternalSystemRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/UpdateExternalSystem',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'UpdateExternalSystem',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_security_health_analytics_custom_module {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityHealthAnalyticsCustomModuleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/UpdateSecurityHealthAnalyticsCustomModule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'UpdateSecurityHealthAnalyticsCustomModule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_big_query_export {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateBigQueryExportRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/CreateBigQueryExport',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'CreateBigQueryExport',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_event_threat_detection_custom_module {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteEventThreatDetectionCustomModuleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/DeleteEventThreatDetectionCustomModule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'DeleteEventThreatDetectionCustomModule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_event_threat_detection_custom_modules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/ListEventThreatDetectionCustomModules',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'ListEventThreatDetectionCustomModules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_event_threat_detection_custom_module {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveEventThreatDetectionCustomModuleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/GetEffectiveEventThreatDetectionCustomModule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'GetEffectiveEventThreatDetectionCustomModule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_create_resource_value_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1.SecurityCenter/BatchCreateResourceValueConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1.SecurityCenter',
        method         => 'BatchCreateResourceValueConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Securitycenter::V1

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Securitycenter::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Securitycenter::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Securitycenter::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/securitycenter/v1/access.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/agent.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/agent_anomaly.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/agent_session.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/application.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/asset.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/attack_exposure.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/attack_path.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/backup_disaster_recovery.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/bigquery_export.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/chokepoint.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/cloud_armor.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/cloud_dlp_data_profile.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/cloud_dlp_inspection.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/compliance.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/connection.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/contact_details.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/container.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/database.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/effective_event_threat_detection_custom_module.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/effective_security_health_analytics_custom_module.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/event_threat_detection_custom_module.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/event_threat_detection_custom_module_validation_errors.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/exfiltration.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/external_exposure.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/external_system.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/file.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/finding.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/folder.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/group_membership.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/iam_binding.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/indicator.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/kernel_rootkit.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/kubernetes.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/label.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/load_balancer.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/log_entry.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/mitre_attack.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/mute_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/notebook.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/notification_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/notification_message.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/org_policy.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/organization_settings.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/process.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/resource.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/resource_value_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/run_asset_discovery_response.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/security_health_analytics_custom_config.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/security_health_analytics_custom_module.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/security_marks.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/security_posture.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/securitycenter_service.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/simulation.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/source.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/toxic_combination.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/valued_resource.proto>

=item * C<googleapis/google/cloud/securitycenter/v1/vulnerability.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Securitycenter::V1->new(
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

=item * B<bulk_mute_findings>

    my $response = $client->bulk_mute_findings(
        parent                   => $parent,
        filter                   => $filter,
        mute_annotation          => $mute_annotation,
        mute_state               => $mute_state,
    );

Calls the RPC method C<BulkMuteFindings> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<mute_annotation> - C<string>

=item * C<mute_state> - L<Google::Cloud::Securitycenter::V1::SecuritycenterService::MuteState>

=back

=item * B<create_source>

    my $response = $client->create_source(
        parent                   => $parent,
        source                   => $source,
    );

Calls the RPC method C<CreateSource> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSourceRequest>

Returns: L<Google::Cloud::Securitycenter::V1::Source::Source>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<source> - L<Google::Cloud::Securitycenter::V1::Source::Source>

=back

=item * B<get_effective_security_health_analytics_custom_module>

    my $response = $client->get_effective_security_health_analytics_custom_module(
        name                     => $name,
    );

Calls the RPC method C<GetEffectiveSecurityHealthAnalyticsCustomModule> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest>

Returns: L<Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_findings>

    my $response = $client->list_findings(
        parent                   => $parent,
        filter                   => $filter,
        order_by                 => $order_by,
        read_time                => $read_time,
        compare_duration         => $compare_duration,
        field_mask               => $field_mask,
        page_token               => $page_token,
        page_size                => $page_size,
    );

Calls the RPC method C<ListFindings> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsRequest>

Returns: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=item * C<read_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<compare_duration> - L<Google::Protobuf::Duration::Duration>

=item * C<field_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=back

=item * B<list_security_health_analytics_custom_modules>

    my $response = $client->list_security_health_analytics_custom_modules(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSecurityHealthAnalyticsCustomModules> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesRequest>

Returns: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_external_system>

    my $response = $client->update_external_system(
        external_system          => $external_system,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateExternalSystem> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateExternalSystemRequest>

Returns: L<Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem>

Parameters:

=over 4

=item * C<external_system> - L<Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<update_security_health_analytics_custom_module>

    my $response = $client->update_security_health_analytics_custom_module(
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateSecurityHealthAnalyticsCustomModule> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityHealthAnalyticsCustomModuleRequest>

Returns: L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule>

Parameters:

=over 4

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_big_query_export>

    my $response = $client->create_big_query_export(
        parent                   => $parent,
        big_query_export         => $big_query_export,
        big_query_export_id      => $big_query_export_id,
    );

Calls the RPC method C<CreateBigQueryExport> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateBigQueryExportRequest>

Returns: L<Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<big_query_export> - L<Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport>

=item * C<big_query_export_id> - C<string>

=back

=item * B<delete_event_threat_detection_custom_module>

    my $response = $client->delete_event_threat_detection_custom_module(
        name                     => $name,
    );

Calls the RPC method C<DeleteEventThreatDetectionCustomModule> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteEventThreatDetectionCustomModuleRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_event_threat_detection_custom_modules>

    my $response = $client->list_event_threat_detection_custom_modules(
        parent                   => $parent,
        page_token               => $page_token,
        page_size                => $page_size,
    );

Calls the RPC method C<ListEventThreatDetectionCustomModules> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesRequest>

Returns: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=back

=item * B<get_effective_event_threat_detection_custom_module>

    my $response = $client->get_effective_event_threat_detection_custom_module(
        name                     => $name,
    );

Calls the RPC method C<GetEffectiveEventThreatDetectionCustomModule> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveEventThreatDetectionCustomModuleRequest>

Returns: L<Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<batch_create_resource_value_configs>

    my $response = $client->batch_create_resource_value_configs(
        parent                   => $parent,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchCreateResourceValueConfigs> on C<google.cloud.securitycenter.v1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsRequest>

Returns: L<Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<requests> - ArrayRef of L<Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateResourceValueConfigRequest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
