package Google::Cloud::Compute::V1::InstancesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1::Compute;

our $VERSION = '0.02';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $target = 'localhost:50051';
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
        # Default high-performance HTTP/2 gRPC client
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub add_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddAccessConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AddAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddNetworkInterfaceInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AddNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddResourcePoliciesInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AddResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AggregatedListInstancesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceAggregatedList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub attach_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AttachDiskInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AttachDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bulk_insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::BulkInsertInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'BulkInsert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteAccessConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'DeleteAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteNetworkInterfaceInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'DeleteNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detach_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DetachDiskInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'DetachDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Instance';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_firewalls {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetEffectiveFirewallsInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstancesGetEffectiveFirewallsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetEffectiveFirewalls',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_guest_attributes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetGuestAttributesInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::GuestAttributes';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetGuestAttributes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetIamPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_screenshot {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetScreenshotInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Screenshot';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetScreenshot',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_serial_port_output {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetSerialPortOutputInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SerialPortOutput';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetSerialPortOutput',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_shielded_instance_identity {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetShieldedInstanceIdentityInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::ShieldedInstanceIdentity';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetShieldedInstanceIdentity',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListInstancesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_referrers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListReferrersInstancesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceListReferrers';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'ListReferrers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub perform_maintenance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PerformMaintenanceInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'PerformMaintenance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveResourcePoliciesInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'RemoveResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub report_host_as_faulty {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ReportHostAsFaultyInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'ReportHostAsFaulty',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResetInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Reset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResumeInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Resume',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub send_diagnostic_interrupt {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SendDiagnosticInterruptInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SendDiagnosticInterruptInstanceResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SendDiagnosticInterrupt',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_deletion_protection {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetDeletionProtectionInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetDeletionProtection',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_disk_auto_delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetDiskAutoDeleteInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetDiskAutoDelete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetIamPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_labels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetLabelsInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetLabels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_machine_resources {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMachineResourcesInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMachineResources',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_machine_type {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMachineTypeInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMachineType',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMetadataInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_min_cpu_platform {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMinCpuPlatformInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMinCpuPlatform',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_name {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetNameInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetName',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_scheduling {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSchedulingInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetScheduling',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_security_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSecurityPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetSecurityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetServiceAccountInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_shielded_instance_integrity_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetShieldedInstanceIntegrityPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetShieldedInstanceIntegrityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_tags {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetTagsInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetTags',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub simulate_maintenance_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SimulateMaintenanceEventInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SimulateMaintenanceEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Start',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_with_encryption_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartWithEncryptionKeyInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'StartWithEncryptionKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Stop',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub suspend {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SuspendInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Suspend',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateAccessConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_display_device {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateDisplayDeviceInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateDisplayDevice',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateNetworkInterfaceInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_shielded_instance_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateShieldedInstanceConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateShieldedInstanceConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::InstancesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::InstancesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::InstancesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::InstancesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::InstancesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::InstancesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::InstancesClient->new(
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

=item * B<add_access_config>

Calls the RPC method C<AddAccessConfig> on the service. Takes a hash of parameters representing the request.

=item * B<add_network_interface>

Calls the RPC method C<AddNetworkInterface> on the service. Takes a hash of parameters representing the request.

=item * B<add_resource_policies>

Calls the RPC method C<AddResourcePolicies> on the service. Takes a hash of parameters representing the request.

=item * B<aggregated_list>

Calls the RPC method C<AggregatedList> on the service. Takes a hash of parameters representing the request.

=item * B<attach_disk>

Calls the RPC method C<AttachDisk> on the service. Takes a hash of parameters representing the request.

=item * B<bulk_insert>

Calls the RPC method C<BulkInsert> on the service. Takes a hash of parameters representing the request.

=item * B<delete>

Calls the RPC method C<Delete> on the service. Takes a hash of parameters representing the request.

=item * B<delete_access_config>

Calls the RPC method C<DeleteAccessConfig> on the service. Takes a hash of parameters representing the request.

=item * B<delete_network_interface>

Calls the RPC method C<DeleteNetworkInterface> on the service. Takes a hash of parameters representing the request.

=item * B<detach_disk>

Calls the RPC method C<DetachDisk> on the service. Takes a hash of parameters representing the request.

=item * B<get>

Calls the RPC method C<Get> on the service. Takes a hash of parameters representing the request.

=item * B<get_effective_firewalls>

Calls the RPC method C<GetEffectiveFirewalls> on the service. Takes a hash of parameters representing the request.

=item * B<get_guest_attributes>

Calls the RPC method C<GetGuestAttributes> on the service. Takes a hash of parameters representing the request.

=item * B<get_iam_policy>

Calls the RPC method C<GetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<get_screenshot>

Calls the RPC method C<GetScreenshot> on the service. Takes a hash of parameters representing the request.

=item * B<get_serial_port_output>

Calls the RPC method C<GetSerialPortOutput> on the service. Takes a hash of parameters representing the request.

=item * B<get_shielded_instance_identity>

Calls the RPC method C<GetShieldedInstanceIdentity> on the service. Takes a hash of parameters representing the request.

=item * B<insert>

Calls the RPC method C<Insert> on the service. Takes a hash of parameters representing the request.

=item * B<list>

Calls the RPC method C<List> on the service. Takes a hash of parameters representing the request.

=item * B<list_referrers>

Calls the RPC method C<ListReferrers> on the service. Takes a hash of parameters representing the request.

=item * B<perform_maintenance>

Calls the RPC method C<PerformMaintenance> on the service. Takes a hash of parameters representing the request.

=item * B<remove_resource_policies>

Calls the RPC method C<RemoveResourcePolicies> on the service. Takes a hash of parameters representing the request.

=item * B<report_host_as_faulty>

Calls the RPC method C<ReportHostAsFaulty> on the service. Takes a hash of parameters representing the request.

=item * B<reset>

Calls the RPC method C<Reset> on the service. Takes a hash of parameters representing the request.

=item * B<resume>

Calls the RPC method C<Resume> on the service. Takes a hash of parameters representing the request.

=item * B<send_diagnostic_interrupt>

Calls the RPC method C<SendDiagnosticInterrupt> on the service. Takes a hash of parameters representing the request.

=item * B<set_deletion_protection>

Calls the RPC method C<SetDeletionProtection> on the service. Takes a hash of parameters representing the request.

=item * B<set_disk_auto_delete>

Calls the RPC method C<SetDiskAutoDelete> on the service. Takes a hash of parameters representing the request.

=item * B<set_iam_policy>

Calls the RPC method C<SetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<set_labels>

Calls the RPC method C<SetLabels> on the service. Takes a hash of parameters representing the request.

=item * B<set_machine_resources>

Calls the RPC method C<SetMachineResources> on the service. Takes a hash of parameters representing the request.

=item * B<set_machine_type>

Calls the RPC method C<SetMachineType> on the service. Takes a hash of parameters representing the request.

=item * B<set_metadata>

Calls the RPC method C<SetMetadata> on the service. Takes a hash of parameters representing the request.

=item * B<set_min_cpu_platform>

Calls the RPC method C<SetMinCpuPlatform> on the service. Takes a hash of parameters representing the request.

=item * B<set_name>

Calls the RPC method C<SetName> on the service. Takes a hash of parameters representing the request.

=item * B<set_scheduling>

Calls the RPC method C<SetScheduling> on the service. Takes a hash of parameters representing the request.

=item * B<set_security_policy>

Calls the RPC method C<SetSecurityPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<set_service_account>

Calls the RPC method C<SetServiceAccount> on the service. Takes a hash of parameters representing the request.

=item * B<set_shielded_instance_integrity_policy>

Calls the RPC method C<SetShieldedInstanceIntegrityPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<set_tags>

Calls the RPC method C<SetTags> on the service. Takes a hash of parameters representing the request.

=item * B<simulate_maintenance_event>

Calls the RPC method C<SimulateMaintenanceEvent> on the service. Takes a hash of parameters representing the request.

=item * B<start>

Calls the RPC method C<Start> on the service. Takes a hash of parameters representing the request.

=item * B<start_with_encryption_key>

Calls the RPC method C<StartWithEncryptionKey> on the service. Takes a hash of parameters representing the request.

=item * B<stop>

Calls the RPC method C<Stop> on the service. Takes a hash of parameters representing the request.

=item * B<suspend>

Calls the RPC method C<Suspend> on the service. Takes a hash of parameters representing the request.

=item * B<test_iam_permissions>

Calls the RPC method C<TestIamPermissions> on the service. Takes a hash of parameters representing the request.

=item * B<update>

Calls the RPC method C<Update> on the service. Takes a hash of parameters representing the request.

=item * B<update_access_config>

Calls the RPC method C<UpdateAccessConfig> on the service. Takes a hash of parameters representing the request.

=item * B<update_display_device>

Calls the RPC method C<UpdateDisplayDevice> on the service. Takes a hash of parameters representing the request.

=item * B<update_network_interface>

Calls the RPC method C<UpdateNetworkInterface> on the service. Takes a hash of parameters representing the request.

=item * B<update_shielded_instance_config>

Calls the RPC method C<UpdateShieldedInstanceConfig> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
