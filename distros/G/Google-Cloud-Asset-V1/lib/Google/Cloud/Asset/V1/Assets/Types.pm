package Google::Cloud::Asset::V1::Assets::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TemporalAsset',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::TemporalAsset'];

coerce 'TemporalAsset',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::TemporalAsset'->new($_) };

declare 'RepeatedTemporalAsset',
    as ArrayRef[TemporalAsset()];

coerce 'RepeatedTemporalAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::TemporalAsset'->new($_) } @$_ ] };

declare 'MapStringTemporalAsset',
    as HashRef[TemporalAsset()];

declare 'PriorAssetState',
    as (Int | Str);

declare 'TimeWindow',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::TimeWindow'];

coerce 'TimeWindow',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::TimeWindow'->new($_) };

declare 'RepeatedTimeWindow',
    as ArrayRef[TimeWindow()];

coerce 'RepeatedTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::TimeWindow'->new($_) } @$_ ] };

declare 'MapStringTimeWindow',
    as HashRef[TimeWindow()];

declare 'AssetEnrichment',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::AssetEnrichment'];

coerce 'AssetEnrichment',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::AssetEnrichment'->new($_) };

declare 'RepeatedAssetEnrichment',
    as ArrayRef[AssetEnrichment()];

coerce 'RepeatedAssetEnrichment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::AssetEnrichment'->new($_) } @$_ ] };

declare 'MapStringAssetEnrichment',
    as HashRef[AssetEnrichment()];

declare 'Asset',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'RelatedAssets',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::RelatedAssets'];

coerce 'RelatedAssets',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::RelatedAssets'->new($_) };

declare 'RepeatedRelatedAssets',
    as ArrayRef[RelatedAssets()];

coerce 'RepeatedRelatedAssets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::RelatedAssets'->new($_) } @$_ ] };

declare 'MapStringRelatedAssets',
    as HashRef[RelatedAssets()];

declare 'RelationshipAttributes',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::RelationshipAttributes'];

coerce 'RelationshipAttributes',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::RelationshipAttributes'->new($_) };

declare 'RepeatedRelationshipAttributes',
    as ArrayRef[RelationshipAttributes()];

coerce 'RepeatedRelationshipAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::RelationshipAttributes'->new($_) } @$_ ] };

declare 'MapStringRelationshipAttributes',
    as HashRef[RelationshipAttributes()];

declare 'RelatedAsset',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::RelatedAsset'];

coerce 'RelatedAsset',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::RelatedAsset'->new($_) };

declare 'RepeatedRelatedAsset',
    as ArrayRef[RelatedAsset()];

coerce 'RepeatedRelatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::RelatedAsset'->new($_) } @$_ ] };

declare 'MapStringRelatedAsset',
    as HashRef[RelatedAsset()];

declare 'Tag',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::Tag'];

coerce 'Tag',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::Tag'->new($_) };

declare 'RepeatedTag',
    as ArrayRef[Tag()];

coerce 'RepeatedTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::Tag'->new($_) } @$_ ] };

declare 'MapStringTag',
    as HashRef[Tag()];

declare 'EffectiveTagDetails',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::EffectiveTagDetails'];

coerce 'EffectiveTagDetails',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::EffectiveTagDetails'->new($_) };

declare 'RepeatedEffectiveTagDetails',
    as ArrayRef[EffectiveTagDetails()];

coerce 'RepeatedEffectiveTagDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::EffectiveTagDetails'->new($_) } @$_ ] };

declare 'MapStringEffectiveTagDetails',
    as HashRef[EffectiveTagDetails()];

declare 'ResourceSearchResult',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::ResourceSearchResult'];

coerce 'ResourceSearchResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult'->new($_) };

declare 'RepeatedResourceSearchResult',
    as ArrayRef[ResourceSearchResult()];

coerce 'RepeatedResourceSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult'->new($_) } @$_ ] };

declare 'MapStringResourceSearchResult',
    as HashRef[ResourceSearchResult()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::ResourceSearchResult::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RelationshipsEntry',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::ResourceSearchResult::RelationshipsEntry'];

coerce 'RelationshipsEntry',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult::RelationshipsEntry'->new($_) };

declare 'RepeatedRelationshipsEntry',
    as ArrayRef[RelationshipsEntry()];

coerce 'RepeatedRelationshipsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult::RelationshipsEntry'->new($_) } @$_ ] };

declare 'MapStringRelationshipsEntry',
    as HashRef[RelationshipsEntry()];

declare 'SccSecurityMarksEntry',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::ResourceSearchResult::SccSecurityMarksEntry'];

coerce 'SccSecurityMarksEntry',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult::SccSecurityMarksEntry'->new($_) };

declare 'RepeatedSccSecurityMarksEntry',
    as ArrayRef[SccSecurityMarksEntry()];

coerce 'RepeatedSccSecurityMarksEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::ResourceSearchResult::SccSecurityMarksEntry'->new($_) } @$_ ] };

declare 'MapStringSccSecurityMarksEntry',
    as HashRef[SccSecurityMarksEntry()];

declare 'VersionedResource',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::VersionedResource'];

coerce 'VersionedResource',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::VersionedResource'->new($_) };

declare 'RepeatedVersionedResource',
    as ArrayRef[VersionedResource()];

coerce 'RepeatedVersionedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::VersionedResource'->new($_) } @$_ ] };

declare 'MapStringVersionedResource',
    as HashRef[VersionedResource()];

declare 'AttachedResource',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::AttachedResource'];

coerce 'AttachedResource',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::AttachedResource'->new($_) };

declare 'RepeatedAttachedResource',
    as ArrayRef[AttachedResource()];

coerce 'RepeatedAttachedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::AttachedResource'->new($_) } @$_ ] };

declare 'MapStringAttachedResource',
    as HashRef[AttachedResource()];

declare 'RelatedResources',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::RelatedResources'];

coerce 'RelatedResources',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::RelatedResources'->new($_) };

declare 'RepeatedRelatedResources',
    as ArrayRef[RelatedResources()];

coerce 'RepeatedRelatedResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::RelatedResources'->new($_) } @$_ ] };

declare 'MapStringRelatedResources',
    as HashRef[RelatedResources()];

declare 'RelatedResource',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::RelatedResource'];

coerce 'RelatedResource',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::RelatedResource'->new($_) };

declare 'RepeatedRelatedResource',
    as ArrayRef[RelatedResource()];

coerce 'RepeatedRelatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::RelatedResource'->new($_) } @$_ ] };

declare 'MapStringRelatedResource',
    as HashRef[RelatedResource()];

declare 'IamPolicySearchResult',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicySearchResult'];

coerce 'IamPolicySearchResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult'->new($_) };

declare 'RepeatedIamPolicySearchResult',
    as ArrayRef[IamPolicySearchResult()];

coerce 'RepeatedIamPolicySearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult'->new($_) } @$_ ] };

declare 'MapStringIamPolicySearchResult',
    as HashRef[IamPolicySearchResult()];

declare 'Explanation',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation'];

coerce 'Explanation',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation'->new($_) };

declare 'RepeatedExplanation',
    as ArrayRef[Explanation()];

coerce 'RepeatedExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation'->new($_) } @$_ ] };

declare 'MapStringExplanation',
    as HashRef[Explanation()];

declare 'Permissions',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation::Permissions'];

coerce 'Permissions',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation::Permissions'->new($_) };

declare 'RepeatedPermissions',
    as ArrayRef[Permissions()];

coerce 'RepeatedPermissions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation::Permissions'->new($_) } @$_ ] };

declare 'MapStringPermissions',
    as HashRef[Permissions()];

declare 'MatchedPermissionsEntry',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation::MatchedPermissionsEntry'];

coerce 'MatchedPermissionsEntry',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation::MatchedPermissionsEntry'->new($_) };

declare 'RepeatedMatchedPermissionsEntry',
    as ArrayRef[MatchedPermissionsEntry()];

coerce 'RepeatedMatchedPermissionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicySearchResult::Explanation::MatchedPermissionsEntry'->new($_) } @$_ ] };

declare 'MapStringMatchedPermissionsEntry',
    as HashRef[MatchedPermissionsEntry()];

declare 'IamPolicyAnalysisState',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisState'];

coerce 'IamPolicyAnalysisState',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisState'->new($_) };

declare 'RepeatedIamPolicyAnalysisState',
    as ArrayRef[IamPolicyAnalysisState()];

coerce 'RepeatedIamPolicyAnalysisState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisState'->new($_) } @$_ ] };

declare 'MapStringIamPolicyAnalysisState',
    as HashRef[IamPolicyAnalysisState()];

declare 'ConditionEvaluation',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::ConditionEvaluation'];

coerce 'ConditionEvaluation',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::ConditionEvaluation'->new($_) };

declare 'RepeatedConditionEvaluation',
    as ArrayRef[ConditionEvaluation()];

coerce 'RepeatedConditionEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::ConditionEvaluation'->new($_) } @$_ ] };

declare 'MapStringConditionEvaluation',
    as HashRef[ConditionEvaluation()];

declare 'EvaluationValue',
    as (Int | Str);

declare 'IamPolicyAnalysisResult',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult'];

coerce 'IamPolicyAnalysisResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult'->new($_) };

declare 'RepeatedIamPolicyAnalysisResult',
    as ArrayRef[IamPolicyAnalysisResult()];

coerce 'RepeatedIamPolicyAnalysisResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult'->new($_) } @$_ ] };

declare 'MapStringIamPolicyAnalysisResult',
    as HashRef[IamPolicyAnalysisResult()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'Access',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Access'];

coerce 'Access',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Access'->new($_) };

declare 'RepeatedAccess',
    as ArrayRef[Access()];

coerce 'RepeatedAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Access'->new($_) } @$_ ] };

declare 'MapStringAccess',
    as HashRef[Access()];

declare 'Identity',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Identity'];

coerce 'Identity',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Identity'->new($_) };

declare 'RepeatedIdentity',
    as ArrayRef[Identity()];

coerce 'RepeatedIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Identity'->new($_) } @$_ ] };

declare 'MapStringIdentity',
    as HashRef[Identity()];

declare 'Edge',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Edge'];

coerce 'Edge',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Edge'->new($_) };

declare 'RepeatedEdge',
    as ArrayRef[Edge()];

coerce 'RepeatedEdge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::Edge'->new($_) } @$_ ] };

declare 'MapStringEdge',
    as HashRef[Edge()];

declare 'AccessControlList',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::AccessControlList'];

coerce 'AccessControlList',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::AccessControlList'->new($_) };

declare 'RepeatedAccessControlList',
    as ArrayRef[AccessControlList()];

coerce 'RepeatedAccessControlList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::AccessControlList'->new($_) } @$_ ] };

declare 'MapStringAccessControlList',
    as HashRef[AccessControlList()];

declare 'IdentityList',
    as InstanceOf['Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::IdentityList'];

coerce 'IdentityList',
    from HashRef, via { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::IdentityList'->new($_) };

declare 'RepeatedIdentityList',
    as ArrayRef[IdentityList()];

coerce 'RepeatedIdentityList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::Assets::IamPolicyAnalysisResult::IdentityList'->new($_) } @$_ ] };

declare 'MapStringIdentityList',
    as HashRef[IdentityList()];

1;

__END__

=head1 NAME

Google::Cloud::Asset::V1::Assets::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
