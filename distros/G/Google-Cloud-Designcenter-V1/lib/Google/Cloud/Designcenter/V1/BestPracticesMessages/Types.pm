package Google::Cloud::Designcenter::V1::BestPracticesMessages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FetchApplicationAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest'];

coerce 'FetchApplicationAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest'->new($_) };

declare 'RepeatedFetchApplicationAssessmentReportRequest',
    as ArrayRef[FetchApplicationAssessmentReportRequest()];

coerce 'RepeatedFetchApplicationAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringFetchApplicationAssessmentReportRequest',
    as HashRef[FetchApplicationAssessmentReportRequest()];

declare 'FetchApplicationAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportResponse'];

coerce 'FetchApplicationAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportResponse'->new($_) };

declare 'RepeatedFetchApplicationAssessmentReportResponse',
    as ArrayRef[FetchApplicationAssessmentReportResponse()];

coerce 'RepeatedFetchApplicationAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringFetchApplicationAssessmentReportResponse',
    as HashRef[FetchApplicationAssessmentReportResponse()];

declare 'GenerateApplicationAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportRequest'];

coerce 'GenerateApplicationAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportRequest'->new($_) };

declare 'RepeatedGenerateApplicationAssessmentReportRequest',
    as ArrayRef[GenerateApplicationAssessmentReportRequest()];

coerce 'RepeatedGenerateApplicationAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationAssessmentReportRequest',
    as HashRef[GenerateApplicationAssessmentReportRequest()];

declare 'GenerateApplicationAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportResponse'];

coerce 'GenerateApplicationAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportResponse'->new($_) };

declare 'RepeatedGenerateApplicationAssessmentReportResponse',
    as ArrayRef[GenerateApplicationAssessmentReportResponse()];

coerce 'RepeatedGenerateApplicationAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationAssessmentReportResponse',
    as HashRef[GenerateApplicationAssessmentReportResponse()];

declare 'GenerateApplicationTemplateAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportRequest'];

coerce 'GenerateApplicationTemplateAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportRequest'->new($_) };

declare 'RepeatedGenerateApplicationTemplateAssessmentReportRequest',
    as ArrayRef[GenerateApplicationTemplateAssessmentReportRequest()];

coerce 'RepeatedGenerateApplicationTemplateAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationTemplateAssessmentReportRequest',
    as HashRef[GenerateApplicationTemplateAssessmentReportRequest()];

declare 'GenerateApplicationTemplateAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportResponse'];

coerce 'GenerateApplicationTemplateAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportResponse'->new($_) };

declare 'RepeatedGenerateApplicationTemplateAssessmentReportResponse',
    as ArrayRef[GenerateApplicationTemplateAssessmentReportResponse()];

coerce 'RepeatedGenerateApplicationTemplateAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationTemplateAssessmentReportResponse',
    as HashRef[GenerateApplicationTemplateAssessmentReportResponse()];

declare 'GenerateAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportRequest'];

coerce 'GenerateAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportRequest'->new($_) };

declare 'RepeatedGenerateAssessmentReportRequest',
    as ArrayRef[GenerateAssessmentReportRequest()];

coerce 'RepeatedGenerateAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAssessmentReportRequest',
    as HashRef[GenerateAssessmentReportRequest()];

declare 'GenerateAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportResponse'];

coerce 'GenerateAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportResponse'->new($_) };

declare 'RepeatedGenerateAssessmentReportResponse',
    as ArrayRef[GenerateAssessmentReportResponse()];

coerce 'RepeatedGenerateAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAssessmentReportResponse',
    as HashRef[GenerateAssessmentReportResponse()];

declare 'GenerateTerraformPlanAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportRequest'];

coerce 'GenerateTerraformPlanAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportRequest'->new($_) };

declare 'RepeatedGenerateTerraformPlanAssessmentReportRequest',
    as ArrayRef[GenerateTerraformPlanAssessmentReportRequest()];

coerce 'RepeatedGenerateTerraformPlanAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateTerraformPlanAssessmentReportRequest',
    as HashRef[GenerateTerraformPlanAssessmentReportRequest()];

declare 'GenerateTerraformPlanAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportResponse'];

coerce 'GenerateTerraformPlanAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportResponse'->new($_) };

declare 'RepeatedGenerateTerraformPlanAssessmentReportResponse',
    as ArrayRef[GenerateTerraformPlanAssessmentReportResponse()];

coerce 'RepeatedGenerateTerraformPlanAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateTerraformPlanAssessmentReportResponse',
    as HashRef[GenerateTerraformPlanAssessmentReportResponse()];

declare 'FetchFrameworksRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksRequest'];

coerce 'FetchFrameworksRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksRequest'->new($_) };

declare 'RepeatedFetchFrameworksRequest',
    as ArrayRef[FetchFrameworksRequest()];

coerce 'RepeatedFetchFrameworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksRequest'->new($_) } @$_ ] };

declare 'MapStringFetchFrameworksRequest',
    as HashRef[FetchFrameworksRequest()];

declare 'FetchFrameworksResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksResponse'];

coerce 'FetchFrameworksResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksResponse'->new($_) };

declare 'RepeatedFetchFrameworksResponse',
    as ArrayRef[FetchFrameworksResponse()];

coerce 'RepeatedFetchFrameworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksResponse'->new($_) } @$_ ] };

declare 'MapStringFetchFrameworksResponse',
    as HashRef[FetchFrameworksResponse()];

declare 'GetPolicyRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::GetPolicyRequest'];

coerce 'GetPolicyRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GetPolicyRequest'->new($_) };

declare 'RepeatedGetPolicyRequest',
    as ArrayRef[GetPolicyRequest()];

coerce 'RepeatedGetPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::GetPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyRequest',
    as HashRef[GetPolicyRequest()];

declare 'ListPoliciesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesRequest'];

coerce 'ListPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesRequest'->new($_) };

declare 'RepeatedListPoliciesRequest',
    as ArrayRef[ListPoliciesRequest()];

coerce 'RepeatedListPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListPoliciesRequest',
    as HashRef[ListPoliciesRequest()];

declare 'ListPoliciesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesResponse'];

coerce 'ListPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesResponse'->new($_) };

declare 'RepeatedListPoliciesResponse',
    as ArrayRef[ListPoliciesResponse()];

coerce 'RepeatedListPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListPoliciesResponse',
    as HashRef[ListPoliciesResponse()];

declare 'CreatePolicyRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::CreatePolicyRequest'];

coerce 'CreatePolicyRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::CreatePolicyRequest'->new($_) };

declare 'RepeatedCreatePolicyRequest',
    as ArrayRef[CreatePolicyRequest()];

coerce 'RepeatedCreatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::CreatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePolicyRequest',
    as HashRef[CreatePolicyRequest()];

declare 'UpdatePolicyRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::UpdatePolicyRequest'];

coerce 'UpdatePolicyRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::UpdatePolicyRequest'->new($_) };

declare 'RepeatedUpdatePolicyRequest',
    as ArrayRef[UpdatePolicyRequest()];

coerce 'RepeatedUpdatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::UpdatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyRequest',
    as HashRef[UpdatePolicyRequest()];

declare 'DeletePolicyRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPracticesMessages::DeletePolicyRequest'];

coerce 'DeletePolicyRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::DeletePolicyRequest'->new($_) };

declare 'RepeatedDeletePolicyRequest',
    as ArrayRef[DeletePolicyRequest()];

coerce 'RepeatedDeletePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPracticesMessages::DeletePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePolicyRequest',
    as HashRef[DeletePolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::BestPracticesMessages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
