package Google::Cloud::Designcenter::V1::Designcenter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'PreviewOperationMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::PreviewOperationMetadata'];

coerce 'PreviewOperationMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::PreviewOperationMetadata'->new($_) };

declare 'RepeatedPreviewOperationMetadata',
    as ArrayRef[PreviewOperationMetadata()];

coerce 'RepeatedPreviewOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::PreviewOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringPreviewOperationMetadata',
    as HashRef[PreviewOperationMetadata()];

declare 'GenerateAssessmentReportOperationMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::GenerateAssessmentReportOperationMetadata'];

coerce 'GenerateAssessmentReportOperationMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::GenerateAssessmentReportOperationMetadata'->new($_) };

declare 'RepeatedGenerateAssessmentReportOperationMetadata',
    as ArrayRef[GenerateAssessmentReportOperationMetadata()];

coerce 'RepeatedGenerateAssessmentReportOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::GenerateAssessmentReportOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringGenerateAssessmentReportOperationMetadata',
    as HashRef[GenerateAssessmentReportOperationMetadata()];

declare 'AssessmentStep',
    as (Int | Str);

declare 'ApplicationOperationMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::ApplicationOperationMetadata'];

coerce 'ApplicationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::ApplicationOperationMetadata'->new($_) };

declare 'RepeatedApplicationOperationMetadata',
    as ArrayRef[ApplicationOperationMetadata()];

coerce 'RepeatedApplicationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::ApplicationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringApplicationOperationMetadata',
    as HashRef[ApplicationOperationMetadata()];

declare 'ProvisionDeploymentGroupOperationMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::ProvisionDeploymentGroupOperationMetadata'];

coerce 'ProvisionDeploymentGroupOperationMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::ProvisionDeploymentGroupOperationMetadata'->new($_) };

declare 'RepeatedProvisionDeploymentGroupOperationMetadata',
    as ArrayRef[ProvisionDeploymentGroupOperationMetadata()];

coerce 'RepeatedProvisionDeploymentGroupOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::ProvisionDeploymentGroupOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringProvisionDeploymentGroupOperationMetadata',
    as HashRef[ProvisionDeploymentGroupOperationMetadata()];

declare 'DeploymentStep',
    as (Int | Str);

declare 'DeploymentUnitProgress',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::DeploymentUnitProgress'];

coerce 'DeploymentUnitProgress',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::DeploymentUnitProgress'->new($_) };

declare 'RepeatedDeploymentUnitProgress',
    as ArrayRef[DeploymentUnitProgress()];

coerce 'RepeatedDeploymentUnitProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::DeploymentUnitProgress'->new($_) } @$_ ] };

declare 'MapStringDeploymentUnitProgress',
    as HashRef[DeploymentUnitProgress()];

declare 'DeploymentOperationMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::DeploymentOperationMetadata'];

coerce 'DeploymentOperationMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::DeploymentOperationMetadata'->new($_) };

declare 'RepeatedDeploymentOperationMetadata',
    as ArrayRef[DeploymentOperationMetadata()];

coerce 'RepeatedDeploymentOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::DeploymentOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeploymentOperationMetadata',
    as HashRef[DeploymentOperationMetadata()];

declare 'DeploymentAttemptMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Designcenter::DeploymentAttemptMetadata'];

coerce 'DeploymentAttemptMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Designcenter::DeploymentAttemptMetadata'->new($_) };

declare 'RepeatedDeploymentAttemptMetadata',
    as ArrayRef[DeploymentAttemptMetadata()];

coerce 'RepeatedDeploymentAttemptMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Designcenter::DeploymentAttemptMetadata'->new($_) } @$_ ] };

declare 'MapStringDeploymentAttemptMetadata',
    as HashRef[DeploymentAttemptMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Designcenter::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
