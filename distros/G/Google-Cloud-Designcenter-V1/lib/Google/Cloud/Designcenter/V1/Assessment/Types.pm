package Google::Cloud::Designcenter::V1::Assessment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DomainAssessmentReport',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport'];

coerce 'DomainAssessmentReport',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport'->new($_) };

declare 'RepeatedDomainAssessmentReport',
    as ArrayRef[DomainAssessmentReport()];

coerce 'RepeatedDomainAssessmentReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport'->new($_) } @$_ ] };

declare 'MapStringDomainAssessmentReport',
    as HashRef[DomainAssessmentReport()];

declare 'Status',
    as (Int | Str);

declare 'DomainRedirectInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport::DomainRedirectInfo'];

coerce 'DomainRedirectInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport::DomainRedirectInfo'->new($_) };

declare 'RepeatedDomainRedirectInfo',
    as ArrayRef[DomainRedirectInfo()];

coerce 'RepeatedDomainRedirectInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport::DomainRedirectInfo'->new($_) } @$_ ] };

declare 'MapStringDomainRedirectInfo',
    as HashRef[DomainRedirectInfo()];

declare 'ScoreCard',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::ScoreCard'];

coerce 'ScoreCard',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::ScoreCard'->new($_) };

declare 'RepeatedScoreCard',
    as ArrayRef[ScoreCard()];

coerce 'RepeatedScoreCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::ScoreCard'->new($_) } @$_ ] };

declare 'MapStringScoreCard',
    as HashRef[ScoreCard()];

declare 'ApplyCondition',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::ApplyCondition'];

coerce 'ApplyCondition',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::ApplyCondition'->new($_) };

declare 'RepeatedApplyCondition',
    as ArrayRef[ApplyCondition()];

coerce 'RepeatedApplyCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::ApplyCondition'->new($_) } @$_ ] };

declare 'MapStringApplyCondition',
    as HashRef[ApplyCondition()];

declare 'SkippedDomain',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::SkippedDomain'];

coerce 'SkippedDomain',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::SkippedDomain'->new($_) };

declare 'RepeatedSkippedDomain',
    as ArrayRef[SkippedDomain()];

coerce 'RepeatedSkippedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::SkippedDomain'->new($_) } @$_ ] };

declare 'MapStringSkippedDomain',
    as HashRef[SkippedDomain()];

declare 'Reason',
    as (Int | Str);

declare 'Domain',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::Domain'];

coerce 'Domain',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::Domain'->new($_) };

declare 'RepeatedDomain',
    as ArrayRef[Domain()];

coerce 'RepeatedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::Domain'->new($_) } @$_ ] };

declare 'MapStringDomain',
    as HashRef[Domain()];

declare 'Framework',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::Framework'];

coerce 'Framework',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::Framework'->new($_) };

declare 'RepeatedFramework',
    as ArrayRef[Framework()];

coerce 'RepeatedFramework',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::Framework'->new($_) } @$_ ] };

declare 'MapStringFramework',
    as HashRef[Framework()];

declare 'DeploymentStatus',
    as (Int | Str);

declare 'CloudControl',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::CloudControl'];

coerce 'CloudControl',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::CloudControl'->new($_) };

declare 'RepeatedCloudControl',
    as ArrayRef[CloudControl()];

coerce 'RepeatedCloudControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::CloudControl'->new($_) } @$_ ] };

declare 'MapStringCloudControl',
    as HashRef[CloudControl()];

declare 'EnforcementMode',
    as (Int | Str);

declare 'ParameterSpec',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::ParameterSpec'];

coerce 'ParameterSpec',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::ParameterSpec'->new($_) };

declare 'RepeatedParameterSpec',
    as ArrayRef[ParameterSpec()];

coerce 'RepeatedParameterSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::ParameterSpec'->new($_) } @$_ ] };

declare 'MapStringParameterSpec',
    as HashRef[ParameterSpec()];

declare 'ValueType',
    as (Int | Str);

declare 'AdcMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::AdcMetadata'];

coerce 'AdcMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::AdcMetadata'->new($_) };

declare 'RepeatedAdcMetadata',
    as ArrayRef[AdcMetadata()];

coerce 'RepeatedAdcMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::AdcMetadata'->new($_) } @$_ ] };

declare 'MapStringAdcMetadata',
    as HashRef[AdcMetadata()];

declare 'AssessedFramework',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::AssessedFramework'];

coerce 'AssessedFramework',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::AssessedFramework'->new($_) };

declare 'RepeatedAssessedFramework',
    as ArrayRef[AssessedFramework()];

coerce 'RepeatedAssessedFramework',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::AssessedFramework'->new($_) } @$_ ] };

declare 'MapStringAssessedFramework',
    as HashRef[AssessedFramework()];

declare 'AssessmentFinding',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::AssessmentFinding'];

coerce 'AssessmentFinding',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::AssessmentFinding'->new($_) };

declare 'RepeatedAssessmentFinding',
    as ArrayRef[AssessmentFinding()];

coerce 'RepeatedAssessmentFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::AssessmentFinding'->new($_) } @$_ ] };

declare 'MapStringAssessmentFinding',
    as HashRef[AssessmentFinding()];

declare 'Type',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'FindingADCMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::AssessmentFinding::FindingADCMetadata'];

coerce 'FindingADCMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::AssessmentFinding::FindingADCMetadata'->new($_) };

declare 'RepeatedFindingADCMetadata',
    as ArrayRef[FindingADCMetadata()];

coerce 'RepeatedFindingADCMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::AssessmentFinding::FindingADCMetadata'->new($_) } @$_ ] };

declare 'MapStringFindingADCMetadata',
    as HashRef[FindingADCMetadata()];

declare 'SCCMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::SCCMetadata'];

coerce 'SCCMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::SCCMetadata'->new($_) };

declare 'RepeatedSCCMetadata',
    as ArrayRef[SCCMetadata()];

coerce 'RepeatedSCCMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::SCCMetadata'->new($_) } @$_ ] };

declare 'MapStringSCCMetadata',
    as HashRef[SCCMetadata()];

declare 'AssetDetails',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::AssetDetails'];

coerce 'AssetDetails',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::AssetDetails'->new($_) };

declare 'RepeatedAssetDetails',
    as ArrayRef[AssetDetails()];

coerce 'RepeatedAssetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::AssetDetails'->new($_) } @$_ ] };

declare 'MapStringAssetDetails',
    as HashRef[AssetDetails()];

declare 'RemediationStep',
    as InstanceOf['Google::Cloud::Designcenter::V1::Assessment::RemediationStep'];

coerce 'RemediationStep',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Assessment::RemediationStep'->new($_) };

declare 'RepeatedRemediationStep',
    as ArrayRef[RemediationStep()];

coerce 'RepeatedRemediationStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Assessment::RemediationStep'->new($_) } @$_ ] };

declare 'MapStringRemediationStep',
    as HashRef[RemediationStep()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Assessment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
