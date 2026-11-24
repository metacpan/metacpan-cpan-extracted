package Google::Cloud::Cloudsecuritycompliance::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Cloudsecuritycompliance::V1::Common;
use Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService;
use Google::Cloud::Cloudsecuritycompliance::V1::Monitoring;
use Google::Cloud::Cloudsecuritycompliance::V1::Audit;
use Google::Cloud::Cloudsecuritycompliance::V1::Config;
use Google::Cloud::Cloudsecuritycompliance::V1::Deployment;

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

    my $target = 'cloudsecuritycompliance.googleapis.com:443';
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

sub generate_framework_audit_scope_report {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.cloudsecuritycompliance.v1.Audit/GenerateFrameworkAuditScopeReport',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Audit',
        method         => 'GenerateFrameworkAuditScopeReport',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cm_enrollment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService/UpdateCmEnrollment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService',
        method         => 'UpdateCmEnrollment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub calculate_effective_cm_enrollment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService/CalculateEffectiveCmEnrollment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService',
        method         => 'CalculateEffectiveCmEnrollment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_frameworks {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.cloudsecuritycompliance.v1.Config/ListFrameworks',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'ListFrameworks',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_framework_deployment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CreateFrameworkDeploymentRequest';
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
            path           => '/google.cloud.cloudsecuritycompliance.v1.Deployment/CreateFrameworkDeployment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Deployment',
        method         => 'CreateFrameworkDeployment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_framework_compliance_summaries {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.cloudsecuritycompliance.v1.Monitoring/ListFrameworkComplianceSummaries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Monitoring',
        method         => 'ListFrameworkComplianceSummaries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Cloudsecuritycompliance::V1

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Cloudsecuritycompliance::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Cloudsecuritycompliance::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Cloudsecuritycompliance::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Cloudsecuritycompliance::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/cloudsecuritycompliance/v1/audit.proto>

=item * C<googleapis/google/cloud/cloudsecuritycompliance/v1/cm_enrollment_service.proto>

=item * C<googleapis/google/cloud/cloudsecuritycompliance/v1/common.proto>

=item * C<googleapis/google/cloud/cloudsecuritycompliance/v1/config.proto>

=item * C<googleapis/google/cloud/cloudsecuritycompliance/v1/deployment.proto>

=item * C<googleapis/google/cloud/cloudsecuritycompliance/v1/monitoring.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Cloudsecuritycompliance::V1->new(
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

=item * B<generate_framework_audit_scope_report>

    my $response = $client->generate_framework_audit_scope_report(
        scope                    => $scope,
        report_format            => $report_format,
        compliance_framework     => $compliance_framework,
    );

Calls the RPC method C<GenerateFrameworkAuditScopeReport> on C<google.cloud.cloudsecuritycompliance.v1.Audit>.

Request: L<Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportRequest>

Returns: L<Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse>

Parameters:

=over 4

=item * C<scope> - C<string>

=item * C<report_format> - L<Google::Cloud::Cloudsecuritycompliance::V1::Audit::Format>

=item * C<compliance_framework> - C<string>

=back

=item * B<update_cm_enrollment>

    my $response = $client->update_cm_enrollment(
        cm_enrollment            => $cm_enrollment,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateCmEnrollment> on C<google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService>.

Request: L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest>

Returns: L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment>

Parameters:

=over 4

=item * C<cm_enrollment> - L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<calculate_effective_cm_enrollment>

    my $response = $client->calculate_effective_cm_enrollment(
        name                     => $name,
    );

Calls the RPC method C<CalculateEffectiveCmEnrollment> on C<google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService>.

Request: L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest>

Returns: L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_frameworks>

    my $response = $client->list_frameworks(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListFrameworks> on C<google.cloud.cloudsecuritycompliance.v1.Config>.

Request: L<Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest>

Returns: L<Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_framework_deployment>

    my $response = $client->create_framework_deployment(
        parent                   => $parent,
        framework_deployment_id  => $framework_deployment_id,
        framework_deployment     => $framework_deployment,
    );

Calls the RPC method C<CreateFrameworkDeployment> on C<google.cloud.cloudsecuritycompliance.v1.Deployment>.

Request: L<Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CreateFrameworkDeploymentRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<framework_deployment_id> - C<string>

=item * C<framework_deployment> - L<Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeployment>

=back

=item * B<list_framework_compliance_summaries>

    my $response = $client->list_framework_compliance_summaries(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        view                     => $view,
    );

Calls the RPC method C<ListFrameworkComplianceSummaries> on C<google.cloud.cloudsecuritycompliance.v1.Monitoring>.

Request: L<Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesRequest>

Returns: L<Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<view> - L<Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceSummaryView>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
