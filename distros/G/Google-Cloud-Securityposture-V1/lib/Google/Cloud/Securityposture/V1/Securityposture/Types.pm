package Google::Cloud::Securityposture::V1::Securityposture::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Posture',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::Posture'];

coerce 'Posture',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::Posture'->new($_) };

declare 'RepeatedPosture',
    as ArrayRef[Posture()];

coerce 'RepeatedPosture',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::Posture'->new($_) } @$_ ] };

declare 'MapStringPosture',
    as HashRef[Posture()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::Posture::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::Posture::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::Posture::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PolicySet',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::PolicySet'];

coerce 'PolicySet',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::PolicySet'->new($_) };

declare 'RepeatedPolicySet',
    as ArrayRef[PolicySet()];

coerce 'RepeatedPolicySet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::PolicySet'->new($_) } @$_ ] };

declare 'MapStringPolicySet',
    as HashRef[PolicySet()];

declare 'Policy',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'ComplianceStandard',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::Policy::ComplianceStandard'];

coerce 'ComplianceStandard',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::Policy::ComplianceStandard'->new($_) };

declare 'RepeatedComplianceStandard',
    as ArrayRef[ComplianceStandard()];

coerce 'RepeatedComplianceStandard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::Policy::ComplianceStandard'->new($_) } @$_ ] };

declare 'MapStringComplianceStandard',
    as HashRef[ComplianceStandard()];

declare 'Constraint',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::Constraint'];

coerce 'Constraint',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::Constraint'->new($_) };

declare 'RepeatedConstraint',
    as ArrayRef[Constraint()];

coerce 'RepeatedConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::Constraint'->new($_) } @$_ ] };

declare 'MapStringConstraint',
    as HashRef[Constraint()];

declare 'ListPosturesRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPosturesRequest'];

coerce 'ListPosturesRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPosturesRequest'->new($_) };

declare 'RepeatedListPosturesRequest',
    as ArrayRef[ListPosturesRequest()];

coerce 'RepeatedListPosturesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPosturesRequest'->new($_) } @$_ ] };

declare 'MapStringListPosturesRequest',
    as HashRef[ListPosturesRequest()];

declare 'ListPosturesResponse',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPosturesResponse'];

coerce 'ListPosturesResponse',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPosturesResponse'->new($_) };

declare 'RepeatedListPosturesResponse',
    as ArrayRef[ListPosturesResponse()];

coerce 'RepeatedListPosturesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPosturesResponse'->new($_) } @$_ ] };

declare 'MapStringListPosturesResponse',
    as HashRef[ListPosturesResponse()];

declare 'ListPostureRevisionsRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPostureRevisionsRequest'];

coerce 'ListPostureRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureRevisionsRequest'->new($_) };

declare 'RepeatedListPostureRevisionsRequest',
    as ArrayRef[ListPostureRevisionsRequest()];

coerce 'RepeatedListPostureRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPostureRevisionsRequest',
    as HashRef[ListPostureRevisionsRequest()];

declare 'ListPostureRevisionsResponse',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPostureRevisionsResponse'];

coerce 'ListPostureRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureRevisionsResponse'->new($_) };

declare 'RepeatedListPostureRevisionsResponse',
    as ArrayRef[ListPostureRevisionsResponse()];

coerce 'RepeatedListPostureRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPostureRevisionsResponse',
    as HashRef[ListPostureRevisionsResponse()];

declare 'GetPostureRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::GetPostureRequest'];

coerce 'GetPostureRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::GetPostureRequest'->new($_) };

declare 'RepeatedGetPostureRequest',
    as ArrayRef[GetPostureRequest()];

coerce 'RepeatedGetPostureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::GetPostureRequest'->new($_) } @$_ ] };

declare 'MapStringGetPostureRequest',
    as HashRef[GetPostureRequest()];

declare 'CreatePostureRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::CreatePostureRequest'];

coerce 'CreatePostureRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::CreatePostureRequest'->new($_) };

declare 'RepeatedCreatePostureRequest',
    as ArrayRef[CreatePostureRequest()];

coerce 'RepeatedCreatePostureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::CreatePostureRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePostureRequest',
    as HashRef[CreatePostureRequest()];

declare 'UpdatePostureRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::UpdatePostureRequest'];

coerce 'UpdatePostureRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::UpdatePostureRequest'->new($_) };

declare 'RepeatedUpdatePostureRequest',
    as ArrayRef[UpdatePostureRequest()];

coerce 'RepeatedUpdatePostureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::UpdatePostureRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePostureRequest',
    as HashRef[UpdatePostureRequest()];

declare 'DeletePostureRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::DeletePostureRequest'];

coerce 'DeletePostureRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::DeletePostureRequest'->new($_) };

declare 'RepeatedDeletePostureRequest',
    as ArrayRef[DeletePostureRequest()];

coerce 'RepeatedDeletePostureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::DeletePostureRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePostureRequest',
    as HashRef[DeletePostureRequest()];

declare 'ExtractPostureRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ExtractPostureRequest'];

coerce 'ExtractPostureRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ExtractPostureRequest'->new($_) };

declare 'RepeatedExtractPostureRequest',
    as ArrayRef[ExtractPostureRequest()];

coerce 'RepeatedExtractPostureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ExtractPostureRequest'->new($_) } @$_ ] };

declare 'MapStringExtractPostureRequest',
    as HashRef[ExtractPostureRequest()];

declare 'PostureDeployment',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::PostureDeployment'];

coerce 'PostureDeployment',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::PostureDeployment'->new($_) };

declare 'RepeatedPostureDeployment',
    as ArrayRef[PostureDeployment()];

coerce 'RepeatedPostureDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::PostureDeployment'->new($_) } @$_ ] };

declare 'MapStringPostureDeployment',
    as HashRef[PostureDeployment()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::PostureDeployment::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::PostureDeployment::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::PostureDeployment::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ListPostureDeploymentsRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPostureDeploymentsRequest'];

coerce 'ListPostureDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureDeploymentsRequest'->new($_) };

declare 'RepeatedListPostureDeploymentsRequest',
    as ArrayRef[ListPostureDeploymentsRequest()];

coerce 'RepeatedListPostureDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListPostureDeploymentsRequest',
    as HashRef[ListPostureDeploymentsRequest()];

declare 'ListPostureDeploymentsResponse',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPostureDeploymentsResponse'];

coerce 'ListPostureDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureDeploymentsResponse'->new($_) };

declare 'RepeatedListPostureDeploymentsResponse',
    as ArrayRef[ListPostureDeploymentsResponse()];

coerce 'RepeatedListPostureDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListPostureDeploymentsResponse',
    as HashRef[ListPostureDeploymentsResponse()];

declare 'GetPostureDeploymentRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::GetPostureDeploymentRequest'];

coerce 'GetPostureDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::GetPostureDeploymentRequest'->new($_) };

declare 'RepeatedGetPostureDeploymentRequest',
    as ArrayRef[GetPostureDeploymentRequest()];

coerce 'RepeatedGetPostureDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::GetPostureDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetPostureDeploymentRequest',
    as HashRef[GetPostureDeploymentRequest()];

declare 'CreatePostureDeploymentRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::CreatePostureDeploymentRequest'];

coerce 'CreatePostureDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::CreatePostureDeploymentRequest'->new($_) };

declare 'RepeatedCreatePostureDeploymentRequest',
    as ArrayRef[CreatePostureDeploymentRequest()];

coerce 'RepeatedCreatePostureDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::CreatePostureDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePostureDeploymentRequest',
    as HashRef[CreatePostureDeploymentRequest()];

declare 'UpdatePostureDeploymentRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::UpdatePostureDeploymentRequest'];

coerce 'UpdatePostureDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::UpdatePostureDeploymentRequest'->new($_) };

declare 'RepeatedUpdatePostureDeploymentRequest',
    as ArrayRef[UpdatePostureDeploymentRequest()];

coerce 'RepeatedUpdatePostureDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::UpdatePostureDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePostureDeploymentRequest',
    as HashRef[UpdatePostureDeploymentRequest()];

declare 'DeletePostureDeploymentRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::DeletePostureDeploymentRequest'];

coerce 'DeletePostureDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::DeletePostureDeploymentRequest'->new($_) };

declare 'RepeatedDeletePostureDeploymentRequest',
    as ArrayRef[DeletePostureDeploymentRequest()];

coerce 'RepeatedDeletePostureDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::DeletePostureDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePostureDeploymentRequest',
    as HashRef[DeletePostureDeploymentRequest()];

declare 'PostureTemplate',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::PostureTemplate'];

coerce 'PostureTemplate',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::PostureTemplate'->new($_) };

declare 'RepeatedPostureTemplate',
    as ArrayRef[PostureTemplate()];

coerce 'RepeatedPostureTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::PostureTemplate'->new($_) } @$_ ] };

declare 'MapStringPostureTemplate',
    as HashRef[PostureTemplate()];

declare 'State',
    as (Int | Str);

declare 'ListPostureTemplatesRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPostureTemplatesRequest'];

coerce 'ListPostureTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureTemplatesRequest'->new($_) };

declare 'RepeatedListPostureTemplatesRequest',
    as ArrayRef[ListPostureTemplatesRequest()];

coerce 'RepeatedListPostureTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListPostureTemplatesRequest',
    as HashRef[ListPostureTemplatesRequest()];

declare 'ListPostureTemplatesResponse',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::ListPostureTemplatesResponse'];

coerce 'ListPostureTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureTemplatesResponse'->new($_) };

declare 'RepeatedListPostureTemplatesResponse',
    as ArrayRef[ListPostureTemplatesResponse()];

coerce 'RepeatedListPostureTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::ListPostureTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListPostureTemplatesResponse',
    as HashRef[ListPostureTemplatesResponse()];

declare 'GetPostureTemplateRequest',
    as InstanceOf['Google::Cloud::Securityposture::V1::Securityposture::GetPostureTemplateRequest'];

coerce 'GetPostureTemplateRequest',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::Securityposture::GetPostureTemplateRequest'->new($_) };

declare 'RepeatedGetPostureTemplateRequest',
    as ArrayRef[GetPostureTemplateRequest()];

coerce 'RepeatedGetPostureTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::Securityposture::GetPostureTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetPostureTemplateRequest',
    as HashRef[GetPostureTemplateRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Securityposture::V1::Securityposture::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
