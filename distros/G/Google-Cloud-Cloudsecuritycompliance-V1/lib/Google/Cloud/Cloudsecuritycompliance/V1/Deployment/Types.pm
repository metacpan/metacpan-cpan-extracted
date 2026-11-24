package Google::Cloud::Cloudsecuritycompliance::V1::Deployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeploymentState',
    as (Int | Str);

declare 'FrameworkDeployment',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeployment'];

coerce 'FrameworkDeployment',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeployment'->new($_) };

declare 'RepeatedFrameworkDeployment',
    as ArrayRef[FrameworkDeployment()];

coerce 'RepeatedFrameworkDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeployment'->new($_) } @$_ ] };

declare 'MapStringFrameworkDeployment',
    as HashRef[FrameworkDeployment()];

declare 'CloudControlDeployment',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlDeployment'];

coerce 'CloudControlDeployment',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlDeployment'->new($_) };

declare 'RepeatedCloudControlDeployment',
    as ArrayRef[CloudControlDeployment()];

coerce 'RepeatedCloudControlDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlDeployment'->new($_) } @$_ ] };

declare 'MapStringCloudControlDeployment',
    as HashRef[CloudControlDeployment()];

declare 'TargetResourceConfig',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::TargetResourceConfig'];

coerce 'TargetResourceConfig',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::TargetResourceConfig'->new($_) };

declare 'RepeatedTargetResourceConfig',
    as ArrayRef[TargetResourceConfig()];

coerce 'RepeatedTargetResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::TargetResourceConfig'->new($_) } @$_ ] };

declare 'MapStringTargetResourceConfig',
    as HashRef[TargetResourceConfig()];

declare 'TargetResourceCreationConfig',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::TargetResourceCreationConfig'];

coerce 'TargetResourceCreationConfig',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::TargetResourceCreationConfig'->new($_) };

declare 'RepeatedTargetResourceCreationConfig',
    as ArrayRef[TargetResourceCreationConfig()];

coerce 'RepeatedTargetResourceCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::TargetResourceCreationConfig'->new($_) } @$_ ] };

declare 'MapStringTargetResourceCreationConfig',
    as HashRef[TargetResourceCreationConfig()];

declare 'FolderCreationConfig',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FolderCreationConfig'];

coerce 'FolderCreationConfig',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FolderCreationConfig'->new($_) };

declare 'RepeatedFolderCreationConfig',
    as ArrayRef[FolderCreationConfig()];

coerce 'RepeatedFolderCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FolderCreationConfig'->new($_) } @$_ ] };

declare 'MapStringFolderCreationConfig',
    as HashRef[FolderCreationConfig()];

declare 'ProjectCreationConfig',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ProjectCreationConfig'];

coerce 'ProjectCreationConfig',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ProjectCreationConfig'->new($_) };

declare 'RepeatedProjectCreationConfig',
    as ArrayRef[ProjectCreationConfig()];

coerce 'RepeatedProjectCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ProjectCreationConfig'->new($_) } @$_ ] };

declare 'MapStringProjectCreationConfig',
    as HashRef[ProjectCreationConfig()];

declare 'CloudControlMetadata',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlMetadata'];

coerce 'CloudControlMetadata',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlMetadata'->new($_) };

declare 'RepeatedCloudControlMetadata',
    as ArrayRef[CloudControlMetadata()];

coerce 'RepeatedCloudControlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlMetadata'->new($_) } @$_ ] };

declare 'MapStringCloudControlMetadata',
    as HashRef[CloudControlMetadata()];

declare 'CreateFrameworkDeploymentRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CreateFrameworkDeploymentRequest'];

coerce 'CreateFrameworkDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CreateFrameworkDeploymentRequest'->new($_) };

declare 'RepeatedCreateFrameworkDeploymentRequest',
    as ArrayRef[CreateFrameworkDeploymentRequest()];

coerce 'RepeatedCreateFrameworkDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CreateFrameworkDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFrameworkDeploymentRequest',
    as HashRef[CreateFrameworkDeploymentRequest()];

declare 'DeleteFrameworkDeploymentRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::DeleteFrameworkDeploymentRequest'];

coerce 'DeleteFrameworkDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::DeleteFrameworkDeploymentRequest'->new($_) };

declare 'RepeatedDeleteFrameworkDeploymentRequest',
    as ArrayRef[DeleteFrameworkDeploymentRequest()];

coerce 'RepeatedDeleteFrameworkDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::DeleteFrameworkDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFrameworkDeploymentRequest',
    as HashRef[DeleteFrameworkDeploymentRequest()];

declare 'GetFrameworkDeploymentRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::GetFrameworkDeploymentRequest'];

coerce 'GetFrameworkDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::GetFrameworkDeploymentRequest'->new($_) };

declare 'RepeatedGetFrameworkDeploymentRequest',
    as ArrayRef[GetFrameworkDeploymentRequest()];

coerce 'RepeatedGetFrameworkDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::GetFrameworkDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetFrameworkDeploymentRequest',
    as HashRef[GetFrameworkDeploymentRequest()];

declare 'ListFrameworkDeploymentsRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListFrameworkDeploymentsRequest'];

coerce 'ListFrameworkDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListFrameworkDeploymentsRequest'->new($_) };

declare 'RepeatedListFrameworkDeploymentsRequest',
    as ArrayRef[ListFrameworkDeploymentsRequest()];

coerce 'RepeatedListFrameworkDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListFrameworkDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListFrameworkDeploymentsRequest',
    as HashRef[ListFrameworkDeploymentsRequest()];

declare 'ListFrameworkDeploymentsResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListFrameworkDeploymentsResponse'];

coerce 'ListFrameworkDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListFrameworkDeploymentsResponse'->new($_) };

declare 'RepeatedListFrameworkDeploymentsResponse',
    as ArrayRef[ListFrameworkDeploymentsResponse()];

coerce 'RepeatedListFrameworkDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListFrameworkDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListFrameworkDeploymentsResponse',
    as HashRef[ListFrameworkDeploymentsResponse()];

declare 'GetCloudControlDeploymentRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::GetCloudControlDeploymentRequest'];

coerce 'GetCloudControlDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::GetCloudControlDeploymentRequest'->new($_) };

declare 'RepeatedGetCloudControlDeploymentRequest',
    as ArrayRef[GetCloudControlDeploymentRequest()];

coerce 'RepeatedGetCloudControlDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::GetCloudControlDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetCloudControlDeploymentRequest',
    as HashRef[GetCloudControlDeploymentRequest()];

declare 'ListCloudControlDeploymentsRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListCloudControlDeploymentsRequest'];

coerce 'ListCloudControlDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListCloudControlDeploymentsRequest'->new($_) };

declare 'RepeatedListCloudControlDeploymentsRequest',
    as ArrayRef[ListCloudControlDeploymentsRequest()];

coerce 'RepeatedListCloudControlDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListCloudControlDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListCloudControlDeploymentsRequest',
    as HashRef[ListCloudControlDeploymentsRequest()];

declare 'ListCloudControlDeploymentsResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListCloudControlDeploymentsResponse'];

coerce 'ListCloudControlDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListCloudControlDeploymentsResponse'->new($_) };

declare 'RepeatedListCloudControlDeploymentsResponse',
    as ArrayRef[ListCloudControlDeploymentsResponse()];

coerce 'RepeatedListCloudControlDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::ListCloudControlDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListCloudControlDeploymentsResponse',
    as HashRef[ListCloudControlDeploymentsResponse()];

declare 'CloudControlDeploymentReference',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlDeploymentReference'];

coerce 'CloudControlDeploymentReference',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlDeploymentReference'->new($_) };

declare 'RepeatedCloudControlDeploymentReference',
    as ArrayRef[CloudControlDeploymentReference()];

coerce 'RepeatedCloudControlDeploymentReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CloudControlDeploymentReference'->new($_) } @$_ ] };

declare 'MapStringCloudControlDeploymentReference',
    as HashRef[CloudControlDeploymentReference()];

declare 'FrameworkDeploymentReference',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeploymentReference'];

coerce 'FrameworkDeploymentReference',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeploymentReference'->new($_) };

declare 'RepeatedFrameworkDeploymentReference',
    as ArrayRef[FrameworkDeploymentReference()];

coerce 'RepeatedFrameworkDeploymentReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::FrameworkDeploymentReference'->new($_) } @$_ ] };

declare 'MapStringFrameworkDeploymentReference',
    as HashRef[FrameworkDeploymentReference()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::Deployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
