package Google::Cloud::Designcenter::V1::DeploymentMessages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateApplicationRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::CreateApplicationRequest'];

coerce 'CreateApplicationRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::CreateApplicationRequest'->new($_) };

declare 'RepeatedCreateApplicationRequest',
    as ArrayRef[CreateApplicationRequest()];

coerce 'RepeatedCreateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::CreateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationRequest',
    as HashRef[CreateApplicationRequest()];

declare 'GetApplicationRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::GetApplicationRequest'];

coerce 'GetApplicationRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::GetApplicationRequest'->new($_) };

declare 'RepeatedGetApplicationRequest',
    as ArrayRef[GetApplicationRequest()];

coerce 'RepeatedGetApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::GetApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationRequest',
    as HashRef[GetApplicationRequest()];

declare 'ListApplicationsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ListApplicationsRequest'];

coerce 'ListApplicationsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ListApplicationsRequest'->new($_) };

declare 'RepeatedListApplicationsRequest',
    as ArrayRef[ListApplicationsRequest()];

coerce 'RepeatedListApplicationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ListApplicationsRequest'->new($_) } @$_ ] };

declare 'MapStringListApplicationsRequest',
    as HashRef[ListApplicationsRequest()];

declare 'ListApplicationsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ListApplicationsResponse'];

coerce 'ListApplicationsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ListApplicationsResponse'->new($_) };

declare 'RepeatedListApplicationsResponse',
    as ArrayRef[ListApplicationsResponse()];

coerce 'RepeatedListApplicationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ListApplicationsResponse'->new($_) } @$_ ] };

declare 'MapStringListApplicationsResponse',
    as HashRef[ListApplicationsResponse()];

declare 'UpdateApplicationRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::UpdateApplicationRequest'];

coerce 'UpdateApplicationRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::UpdateApplicationRequest'->new($_) };

declare 'RepeatedUpdateApplicationRequest',
    as ArrayRef[UpdateApplicationRequest()];

coerce 'RepeatedUpdateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::UpdateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationRequest',
    as HashRef[UpdateApplicationRequest()];

declare 'DeleteApplicationRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::DeleteApplicationRequest'];

coerce 'DeleteApplicationRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::DeleteApplicationRequest'->new($_) };

declare 'RepeatedDeleteApplicationRequest',
    as ArrayRef[DeleteApplicationRequest()];

coerce 'RepeatedDeleteApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::DeleteApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationRequest',
    as HashRef[DeleteApplicationRequest()];

declare 'DeployApplicationRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::DeployApplicationRequest'];

coerce 'DeployApplicationRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::DeployApplicationRequest'->new($_) };

declare 'RepeatedDeployApplicationRequest',
    as ArrayRef[DeployApplicationRequest()];

coerce 'RepeatedDeployApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::DeployApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringDeployApplicationRequest',
    as HashRef[DeployApplicationRequest()];

declare 'DeployApplicationResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::DeployApplicationResponse'];

coerce 'DeployApplicationResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::DeployApplicationResponse'->new($_) };

declare 'RepeatedDeployApplicationResponse',
    as ArrayRef[DeployApplicationResponse()];

coerce 'RepeatedDeployApplicationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::DeployApplicationResponse'->new($_) } @$_ ] };

declare 'MapStringDeployApplicationResponse',
    as HashRef[DeployApplicationResponse()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'State',
    as (Int | Str);

declare 'GenerateApplicationIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::GenerateApplicationIaCRequest'];

coerce 'GenerateApplicationIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::GenerateApplicationIaCRequest'->new($_) };

declare 'RepeatedGenerateApplicationIaCRequest',
    as ArrayRef[GenerateApplicationIaCRequest()];

coerce 'RepeatedGenerateApplicationIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::GenerateApplicationIaCRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationIaCRequest',
    as HashRef[GenerateApplicationIaCRequest()];

declare 'GenerateApplicationIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::GenerateApplicationIaCResponse'];

coerce 'GenerateApplicationIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::GenerateApplicationIaCResponse'->new($_) };

declare 'RepeatedGenerateApplicationIaCResponse',
    as ArrayRef[GenerateApplicationIaCResponse()];

coerce 'RepeatedGenerateApplicationIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::GenerateApplicationIaCResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationIaCResponse',
    as HashRef[GenerateApplicationIaCResponse()];

declare 'ExportApplicationIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ExportApplicationIaCRequest'];

coerce 'ExportApplicationIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ExportApplicationIaCRequest'->new($_) };

declare 'RepeatedExportApplicationIaCRequest',
    as ArrayRef[ExportApplicationIaCRequest()];

coerce 'RepeatedExportApplicationIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ExportApplicationIaCRequest'->new($_) } @$_ ] };

declare 'MapStringExportApplicationIaCRequest',
    as HashRef[ExportApplicationIaCRequest()];

declare 'ExportApplicationIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ExportApplicationIaCResponse'];

coerce 'ExportApplicationIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ExportApplicationIaCResponse'->new($_) };

declare 'RepeatedExportApplicationIaCResponse',
    as ArrayRef[ExportApplicationIaCResponse()];

coerce 'RepeatedExportApplicationIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ExportApplicationIaCResponse'->new($_) } @$_ ] };

declare 'MapStringExportApplicationIaCResponse',
    as HashRef[ExportApplicationIaCResponse()];

declare 'ImportApplicationIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ImportApplicationIaCRequest'];

coerce 'ImportApplicationIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ImportApplicationIaCRequest'->new($_) };

declare 'RepeatedImportApplicationIaCRequest',
    as ArrayRef[ImportApplicationIaCRequest()];

coerce 'RepeatedImportApplicationIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ImportApplicationIaCRequest'->new($_) } @$_ ] };

declare 'MapStringImportApplicationIaCRequest',
    as HashRef[ImportApplicationIaCRequest()];

declare 'ImportApplicationIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ImportApplicationIaCResponse'];

coerce 'ImportApplicationIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ImportApplicationIaCResponse'->new($_) };

declare 'RepeatedImportApplicationIaCResponse',
    as ArrayRef[ImportApplicationIaCResponse()];

coerce 'RepeatedImportApplicationIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ImportApplicationIaCResponse'->new($_) } @$_ ] };

declare 'MapStringImportApplicationIaCResponse',
    as HashRef[ImportApplicationIaCResponse()];

declare 'State',
    as (Int | Str);

declare 'PreviewApplicationRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::PreviewApplicationRequest'];

coerce 'PreviewApplicationRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::PreviewApplicationRequest'->new($_) };

declare 'RepeatedPreviewApplicationRequest',
    as ArrayRef[PreviewApplicationRequest()];

coerce 'RepeatedPreviewApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::PreviewApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringPreviewApplicationRequest',
    as HashRef[PreviewApplicationRequest()];

declare 'PreviewApplicationResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::PreviewApplicationResponse'];

coerce 'PreviewApplicationResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::PreviewApplicationResponse'->new($_) };

declare 'RepeatedPreviewApplicationResponse',
    as ArrayRef[PreviewApplicationResponse()];

coerce 'RepeatedPreviewApplicationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::PreviewApplicationResponse'->new($_) } @$_ ] };

declare 'MapStringPreviewApplicationResponse',
    as HashRef[PreviewApplicationResponse()];

declare 'RecommendIAMRolesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::RecommendIAMRolesRequest'];

coerce 'RecommendIAMRolesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::RecommendIAMRolesRequest'->new($_) };

declare 'RepeatedRecommendIAMRolesRequest',
    as ArrayRef[RecommendIAMRolesRequest()];

coerce 'RepeatedRecommendIAMRolesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::RecommendIAMRolesRequest'->new($_) } @$_ ] };

declare 'MapStringRecommendIAMRolesRequest',
    as HashRef[RecommendIAMRolesRequest()];

declare 'RecommendIAMRolesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::RecommendIAMRolesResponse'];

coerce 'RecommendIAMRolesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::RecommendIAMRolesResponse'->new($_) };

declare 'RepeatedRecommendIAMRolesResponse',
    as ArrayRef[RecommendIAMRolesResponse()];

coerce 'RepeatedRecommendIAMRolesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::RecommendIAMRolesResponse'->new($_) } @$_ ] };

declare 'MapStringRecommendIAMRolesResponse',
    as HashRef[RecommendIAMRolesResponse()];

declare 'ConfigureAndDeployTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ConfigureAndDeployTemplateRequest'];

coerce 'ConfigureAndDeployTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ConfigureAndDeployTemplateRequest'->new($_) };

declare 'RepeatedConfigureAndDeployTemplateRequest',
    as ArrayRef[ConfigureAndDeployTemplateRequest()];

coerce 'RepeatedConfigureAndDeployTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ConfigureAndDeployTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringConfigureAndDeployTemplateRequest',
    as HashRef[ConfigureAndDeployTemplateRequest()];

declare 'ConfigureAndDeployTemplateResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentMessages::ConfigureAndDeployTemplateResponse'];

coerce 'ConfigureAndDeployTemplateResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ConfigureAndDeployTemplateResponse'->new($_) };

declare 'RepeatedConfigureAndDeployTemplateResponse',
    as ArrayRef[ConfigureAndDeployTemplateResponse()];

coerce 'RepeatedConfigureAndDeployTemplateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentMessages::ConfigureAndDeployTemplateResponse'->new($_) } @$_ ] };

declare 'MapStringConfigureAndDeployTemplateResponse',
    as HashRef[ConfigureAndDeployTemplateResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::DeploymentMessages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
