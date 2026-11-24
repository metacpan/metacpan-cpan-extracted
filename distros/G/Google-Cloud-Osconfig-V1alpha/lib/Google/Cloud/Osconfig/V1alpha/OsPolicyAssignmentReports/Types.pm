package Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetOSPolicyAssignmentReportRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::GetOSPolicyAssignmentReportRequest'];

coerce 'GetOSPolicyAssignmentReportRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::GetOSPolicyAssignmentReportRequest'->new($_) };

declare 'RepeatedGetOSPolicyAssignmentReportRequest',
    as ArrayRef[GetOSPolicyAssignmentReportRequest()];

coerce 'RepeatedGetOSPolicyAssignmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::GetOSPolicyAssignmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringGetOSPolicyAssignmentReportRequest',
    as HashRef[GetOSPolicyAssignmentReportRequest()];

declare 'ListOSPolicyAssignmentReportsRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsRequest'];

coerce 'ListOSPolicyAssignmentReportsRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsRequest'->new($_) };

declare 'RepeatedListOSPolicyAssignmentReportsRequest',
    as ArrayRef[ListOSPolicyAssignmentReportsRequest()];

coerce 'RepeatedListOSPolicyAssignmentReportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsRequest'->new($_) } @$_ ] };

declare 'MapStringListOSPolicyAssignmentReportsRequest',
    as HashRef[ListOSPolicyAssignmentReportsRequest()];

declare 'ListOSPolicyAssignmentReportsResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsResponse'];

coerce 'ListOSPolicyAssignmentReportsResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsResponse'->new($_) };

declare 'RepeatedListOSPolicyAssignmentReportsResponse',
    as ArrayRef[ListOSPolicyAssignmentReportsResponse()];

coerce 'RepeatedListOSPolicyAssignmentReportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsResponse'->new($_) } @$_ ] };

declare 'MapStringListOSPolicyAssignmentReportsResponse',
    as HashRef[ListOSPolicyAssignmentReportsResponse()];

declare 'OSPolicyAssignmentReport',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport'];

coerce 'OSPolicyAssignmentReport',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport'->new($_) };

declare 'RepeatedOSPolicyAssignmentReport',
    as ArrayRef[OSPolicyAssignmentReport()];

coerce 'RepeatedOSPolicyAssignmentReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport'->new($_) } @$_ ] };

declare 'MapStringOSPolicyAssignmentReport',
    as HashRef[OSPolicyAssignmentReport()];

declare 'OSPolicyCompliance',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance'];

coerce 'OSPolicyCompliance',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance'->new($_) };

declare 'RepeatedOSPolicyCompliance',
    as ArrayRef[OSPolicyCompliance()];

coerce 'RepeatedOSPolicyCompliance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance'->new($_) } @$_ ] };

declare 'MapStringOSPolicyCompliance',
    as HashRef[OSPolicyCompliance()];

declare 'ComplianceState',
    as (Int | Str);

declare 'OSPolicyResourceCompliance',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance'];

coerce 'OSPolicyResourceCompliance',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance'->new($_) };

declare 'RepeatedOSPolicyResourceCompliance',
    as ArrayRef[OSPolicyResourceCompliance()];

coerce 'RepeatedOSPolicyResourceCompliance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance'->new($_) } @$_ ] };

declare 'MapStringOSPolicyResourceCompliance',
    as HashRef[OSPolicyResourceCompliance()];

declare 'ComplianceState',
    as (Int | Str);

declare 'OSPolicyResourceConfigStep',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance::OSPolicyResourceConfigStep'];

coerce 'OSPolicyResourceConfigStep',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance::OSPolicyResourceConfigStep'->new($_) };

declare 'RepeatedOSPolicyResourceConfigStep',
    as ArrayRef[OSPolicyResourceConfigStep()];

coerce 'RepeatedOSPolicyResourceConfigStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance::OSPolicyResourceConfigStep'->new($_) } @$_ ] };

declare 'MapStringOSPolicyResourceConfigStep',
    as HashRef[OSPolicyResourceConfigStep()];

declare 'Type',
    as (Int | Str);

declare 'ExecResourceOutput',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance::ExecResourceOutput'];

coerce 'ExecResourceOutput',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance::ExecResourceOutput'->new($_) };

declare 'RepeatedExecResourceOutput',
    as ArrayRef[ExecResourceOutput()];

coerce 'RepeatedExecResourceOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport::OSPolicyCompliance::OSPolicyResourceCompliance::ExecResourceOutput'->new($_) } @$_ ] };

declare 'MapStringExecResourceOutput',
    as HashRef[ExecResourceOutput()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
