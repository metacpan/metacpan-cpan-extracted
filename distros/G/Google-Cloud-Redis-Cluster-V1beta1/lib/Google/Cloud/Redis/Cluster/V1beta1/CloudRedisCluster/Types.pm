package Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PscConnectionStatus',
    as (Int | Str);

declare 'AuthorizationMode',
    as (Int | Str);

declare 'NodeType',
    as (Int | Str);

declare 'TransitEncryptionMode',
    as (Int | Str);

declare 'ServerCaMode',
    as (Int | Str);

declare 'ConnectionType',
    as (Int | Str);

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'CreateAclPolicyRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CreateAclPolicyRequest'];

coerce 'CreateAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CreateAclPolicyRequest'->new($_) };

declare 'RepeatedCreateAclPolicyRequest',
    as ArrayRef[CreateAclPolicyRequest()];

coerce 'RepeatedCreateAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CreateAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAclPolicyRequest',
    as HashRef[CreateAclPolicyRequest()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'ListAclPoliciesRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPoliciesRequest'];

coerce 'ListAclPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPoliciesRequest'->new($_) };

declare 'RepeatedListAclPoliciesRequest',
    as ArrayRef[ListAclPoliciesRequest()];

coerce 'RepeatedListAclPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAclPoliciesRequest',
    as HashRef[ListAclPoliciesRequest()];

declare 'ListAclPoliciesResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPoliciesResponse'];

coerce 'ListAclPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPoliciesResponse'->new($_) };

declare 'RepeatedListAclPoliciesResponse',
    as ArrayRef[ListAclPoliciesResponse()];

coerce 'RepeatedListAclPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAclPoliciesResponse',
    as HashRef[ListAclPoliciesResponse()];

declare 'ListAclPolicyRevisionsRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPolicyRevisionsRequest'];

coerce 'ListAclPolicyRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPolicyRevisionsRequest'->new($_) };

declare 'RepeatedListAclPolicyRevisionsRequest',
    as ArrayRef[ListAclPolicyRevisionsRequest()];

coerce 'RepeatedListAclPolicyRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPolicyRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAclPolicyRevisionsRequest',
    as HashRef[ListAclPolicyRevisionsRequest()];

declare 'ListAclPolicyRevisionsResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPolicyRevisionsResponse'];

coerce 'ListAclPolicyRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPolicyRevisionsResponse'->new($_) };

declare 'RepeatedListAclPolicyRevisionsResponse',
    as ArrayRef[ListAclPolicyRevisionsResponse()];

coerce 'RepeatedListAclPolicyRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAclPolicyRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAclPolicyRevisionsResponse',
    as HashRef[ListAclPolicyRevisionsResponse()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'UpdateAclPolicyRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::UpdateAclPolicyRequest'];

coerce 'UpdateAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::UpdateAclPolicyRequest'->new($_) };

declare 'RepeatedUpdateAclPolicyRequest',
    as ArrayRef[UpdateAclPolicyRequest()];

coerce 'RepeatedUpdateAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::UpdateAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAclPolicyRequest',
    as HashRef[UpdateAclPolicyRequest()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'GetAclPolicyRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAclPolicyRequest'];

coerce 'GetAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAclPolicyRequest'->new($_) };

declare 'RepeatedGetAclPolicyRequest',
    as ArrayRef[GetAclPolicyRequest()];

coerce 'RepeatedGetAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAclPolicyRequest',
    as HashRef[GetAclPolicyRequest()];

declare 'GetAclPolicyRevisionRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAclPolicyRevisionRequest'];

coerce 'GetAclPolicyRevisionRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAclPolicyRevisionRequest'->new($_) };

declare 'RepeatedGetAclPolicyRevisionRequest',
    as ArrayRef[GetAclPolicyRevisionRequest()];

coerce 'RepeatedGetAclPolicyRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAclPolicyRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetAclPolicyRevisionRequest',
    as HashRef[GetAclPolicyRevisionRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'DeleteAclPolicyRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteAclPolicyRequest'];

coerce 'DeleteAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteAclPolicyRequest'->new($_) };

declare 'RepeatedDeleteAclPolicyRequest',
    as ArrayRef[DeleteAclPolicyRequest()];

coerce 'RepeatedDeleteAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAclPolicyRequest',
    as HashRef[DeleteAclPolicyRequest()];

declare 'GetClusterCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetClusterCertificateAuthorityRequest'];

coerce 'GetClusterCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetClusterCertificateAuthorityRequest'->new($_) };

declare 'RepeatedGetClusterCertificateAuthorityRequest',
    as ArrayRef[GetClusterCertificateAuthorityRequest()];

coerce 'RepeatedGetClusterCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetClusterCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterCertificateAuthorityRequest',
    as HashRef[GetClusterCertificateAuthorityRequest()];

declare 'ListBackupCollectionsRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupCollectionsRequest'];

coerce 'ListBackupCollectionsRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupCollectionsRequest'->new($_) };

declare 'RepeatedListBackupCollectionsRequest',
    as ArrayRef[ListBackupCollectionsRequest()];

coerce 'RepeatedListBackupCollectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupCollectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupCollectionsRequest',
    as HashRef[ListBackupCollectionsRequest()];

declare 'ListBackupCollectionsResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupCollectionsResponse'];

coerce 'ListBackupCollectionsResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupCollectionsResponse'->new($_) };

declare 'RepeatedListBackupCollectionsResponse',
    as ArrayRef[ListBackupCollectionsResponse()];

coerce 'RepeatedListBackupCollectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupCollectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupCollectionsResponse',
    as HashRef[ListBackupCollectionsResponse()];

declare 'GetBackupCollectionRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetBackupCollectionRequest'];

coerce 'GetBackupCollectionRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetBackupCollectionRequest'->new($_) };

declare 'RepeatedGetBackupCollectionRequest',
    as ArrayRef[GetBackupCollectionRequest()];

coerce 'RepeatedGetBackupCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetBackupCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupCollectionRequest',
    as HashRef[GetBackupCollectionRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ExportBackupRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ExportBackupRequest'];

coerce 'ExportBackupRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ExportBackupRequest'->new($_) };

declare 'RepeatedExportBackupRequest',
    as ArrayRef[ExportBackupRequest()];

coerce 'RepeatedExportBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ExportBackupRequest'->new($_) } @$_ ] };

declare 'MapStringExportBackupRequest',
    as HashRef[ExportBackupRequest()];

declare 'BackupClusterRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupClusterRequest'];

coerce 'BackupClusterRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupClusterRequest'->new($_) };

declare 'RepeatedBackupClusterRequest',
    as ArrayRef[BackupClusterRequest()];

coerce 'RepeatedBackupClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupClusterRequest'->new($_) } @$_ ] };

declare 'MapStringBackupClusterRequest',
    as HashRef[BackupClusterRequest()];

declare 'ListTokenAuthUsersRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListTokenAuthUsersRequest'];

coerce 'ListTokenAuthUsersRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListTokenAuthUsersRequest'->new($_) };

declare 'RepeatedListTokenAuthUsersRequest',
    as ArrayRef[ListTokenAuthUsersRequest()];

coerce 'RepeatedListTokenAuthUsersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListTokenAuthUsersRequest'->new($_) } @$_ ] };

declare 'MapStringListTokenAuthUsersRequest',
    as HashRef[ListTokenAuthUsersRequest()];

declare 'ListTokenAuthUsersResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListTokenAuthUsersResponse'];

coerce 'ListTokenAuthUsersResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListTokenAuthUsersResponse'->new($_) };

declare 'RepeatedListTokenAuthUsersResponse',
    as ArrayRef[ListTokenAuthUsersResponse()];

coerce 'RepeatedListTokenAuthUsersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListTokenAuthUsersResponse'->new($_) } @$_ ] };

declare 'MapStringListTokenAuthUsersResponse',
    as HashRef[ListTokenAuthUsersResponse()];

declare 'GetTokenAuthUserRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetTokenAuthUserRequest'];

coerce 'GetTokenAuthUserRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetTokenAuthUserRequest'->new($_) };

declare 'RepeatedGetTokenAuthUserRequest',
    as ArrayRef[GetTokenAuthUserRequest()];

coerce 'RepeatedGetTokenAuthUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetTokenAuthUserRequest'->new($_) } @$_ ] };

declare 'MapStringGetTokenAuthUserRequest',
    as HashRef[GetTokenAuthUserRequest()];

declare 'ListAuthTokensRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAuthTokensRequest'];

coerce 'ListAuthTokensRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAuthTokensRequest'->new($_) };

declare 'RepeatedListAuthTokensRequest',
    as ArrayRef[ListAuthTokensRequest()];

coerce 'RepeatedListAuthTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAuthTokensRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthTokensRequest',
    as HashRef[ListAuthTokensRequest()];

declare 'ListAuthTokensResponse',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAuthTokensResponse'];

coerce 'ListAuthTokensResponse',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAuthTokensResponse'->new($_) };

declare 'RepeatedListAuthTokensResponse',
    as ArrayRef[ListAuthTokensResponse()];

coerce 'RepeatedListAuthTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ListAuthTokensResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthTokensResponse',
    as HashRef[ListAuthTokensResponse()];

declare 'GetAuthTokenRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAuthTokenRequest'];

coerce 'GetAuthTokenRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAuthTokenRequest'->new($_) };

declare 'RepeatedGetAuthTokenRequest',
    as ArrayRef[GetAuthTokenRequest()];

coerce 'RepeatedGetAuthTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetAuthTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthTokenRequest',
    as HashRef[GetAuthTokenRequest()];

declare 'AddTokenAuthUserRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AddTokenAuthUserRequest'];

coerce 'AddTokenAuthUserRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AddTokenAuthUserRequest'->new($_) };

declare 'RepeatedAddTokenAuthUserRequest',
    as ArrayRef[AddTokenAuthUserRequest()];

coerce 'RepeatedAddTokenAuthUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AddTokenAuthUserRequest'->new($_) } @$_ ] };

declare 'MapStringAddTokenAuthUserRequest',
    as HashRef[AddTokenAuthUserRequest()];

declare 'DeleteTokenAuthUserRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteTokenAuthUserRequest'];

coerce 'DeleteTokenAuthUserRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteTokenAuthUserRequest'->new($_) };

declare 'RepeatedDeleteTokenAuthUserRequest',
    as ArrayRef[DeleteTokenAuthUserRequest()];

coerce 'RepeatedDeleteTokenAuthUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteTokenAuthUserRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTokenAuthUserRequest',
    as HashRef[DeleteTokenAuthUserRequest()];

declare 'AddAuthTokenRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AddAuthTokenRequest'];

coerce 'AddAuthTokenRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AddAuthTokenRequest'->new($_) };

declare 'RepeatedAddAuthTokenRequest',
    as ArrayRef[AddAuthTokenRequest()];

coerce 'RepeatedAddAuthTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AddAuthTokenRequest'->new($_) } @$_ ] };

declare 'MapStringAddAuthTokenRequest',
    as HashRef[AddAuthTokenRequest()];

declare 'DeleteAuthTokenRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteAuthTokenRequest'];

coerce 'DeleteAuthTokenRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteAuthTokenRequest'->new($_) };

declare 'RepeatedDeleteAuthTokenRequest',
    as ArrayRef[DeleteAuthTokenRequest()];

coerce 'RepeatedDeleteAuthTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DeleteAuthTokenRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthTokenRequest',
    as HashRef[DeleteAuthTokenRequest()];

declare 'Cluster',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'State',
    as (Int | Str);

declare 'StateInfo',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::StateInfo'];

coerce 'StateInfo',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::StateInfo'->new($_) };

declare 'RepeatedStateInfo',
    as ArrayRef[StateInfo()];

coerce 'RepeatedStateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::StateInfo'->new($_) } @$_ ] };

declare 'MapStringStateInfo',
    as HashRef[StateInfo()];

declare 'UpdateInfo',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::StateInfo::UpdateInfo'];

coerce 'UpdateInfo',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::StateInfo::UpdateInfo'->new($_) };

declare 'RepeatedUpdateInfo',
    as ArrayRef[UpdateInfo()];

coerce 'RepeatedUpdateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::StateInfo::UpdateInfo'->new($_) } @$_ ] };

declare 'MapStringUpdateInfo',
    as HashRef[UpdateInfo()];

declare 'GcsBackupSource',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::GcsBackupSource'];

coerce 'GcsBackupSource',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::GcsBackupSource'->new($_) };

declare 'RepeatedGcsBackupSource',
    as ArrayRef[GcsBackupSource()];

coerce 'RepeatedGcsBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::GcsBackupSource'->new($_) } @$_ ] };

declare 'MapStringGcsBackupSource',
    as HashRef[GcsBackupSource()];

declare 'ManagedBackupSource',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::ManagedBackupSource'];

coerce 'ManagedBackupSource',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::ManagedBackupSource'->new($_) };

declare 'RepeatedManagedBackupSource',
    as ArrayRef[ManagedBackupSource()];

coerce 'RepeatedManagedBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::ManagedBackupSource'->new($_) } @$_ ] };

declare 'MapStringManagedBackupSource',
    as HashRef[ManagedBackupSource()];

declare 'RedisConfigsEntry',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::RedisConfigsEntry'];

coerce 'RedisConfigsEntry',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::RedisConfigsEntry'->new($_) };

declare 'RepeatedRedisConfigsEntry',
    as ArrayRef[RedisConfigsEntry()];

coerce 'RepeatedRedisConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Cluster::RedisConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringRedisConfigsEntry',
    as HashRef[RedisConfigsEntry()];

declare 'AclPolicyInfo',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyInfo'];

coerce 'AclPolicyInfo',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyInfo'->new($_) };

declare 'RepeatedAclPolicyInfo',
    as ArrayRef[AclPolicyInfo()];

coerce 'RepeatedAclPolicyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyInfo'->new($_) } @$_ ] };

declare 'MapStringAclPolicyInfo',
    as HashRef[AclPolicyInfo()];

declare 'AclPolicy',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicy'];

coerce 'AclPolicy',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicy'->new($_) };

declare 'RepeatedAclPolicy',
    as ArrayRef[AclPolicy()];

coerce 'RepeatedAclPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicy'->new($_) } @$_ ] };

declare 'MapStringAclPolicy',
    as HashRef[AclPolicy()];

declare 'State',
    as (Int | Str);

declare 'AclPolicyRevisionStatus',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyRevisionStatus'];

coerce 'AclPolicyRevisionStatus',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyRevisionStatus'->new($_) };

declare 'RepeatedAclPolicyRevisionStatus',
    as ArrayRef[AclPolicyRevisionStatus()];

coerce 'RepeatedAclPolicyRevisionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyRevisionStatus'->new($_) } @$_ ] };

declare 'MapStringAclPolicyRevisionStatus',
    as HashRef[AclPolicyRevisionStatus()];

declare 'State',
    as (Int | Str);

declare 'ClusterAclPolicyAttachment',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterAclPolicyAttachment'];

coerce 'ClusterAclPolicyAttachment',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterAclPolicyAttachment'->new($_) };

declare 'RepeatedClusterAclPolicyAttachment',
    as ArrayRef[ClusterAclPolicyAttachment()];

coerce 'RepeatedClusterAclPolicyAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterAclPolicyAttachment'->new($_) } @$_ ] };

declare 'MapStringClusterAclPolicyAttachment',
    as HashRef[ClusterAclPolicyAttachment()];

declare 'AclPolicyRevision',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyRevision'];

coerce 'AclPolicyRevision',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyRevision'->new($_) };

declare 'RepeatedAclPolicyRevision',
    as ArrayRef[AclPolicyRevision()];

coerce 'RepeatedAclPolicyRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclPolicyRevision'->new($_) } @$_ ] };

declare 'MapStringAclPolicyRevision',
    as HashRef[AclPolicyRevision()];

declare 'AclRule',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclRule'];

coerce 'AclRule',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclRule'->new($_) };

declare 'RepeatedAclRule',
    as ArrayRef[AclRule()];

coerce 'RepeatedAclRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AclRule'->new($_) } @$_ ] };

declare 'MapStringAclRule',
    as HashRef[AclRule()];

declare 'AutomatedBackupConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AutomatedBackupConfig'];

coerce 'AutomatedBackupConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AutomatedBackupConfig'->new($_) };

declare 'RepeatedAutomatedBackupConfig',
    as ArrayRef[AutomatedBackupConfig()];

coerce 'RepeatedAutomatedBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AutomatedBackupConfig'->new($_) } @$_ ] };

declare 'MapStringAutomatedBackupConfig',
    as HashRef[AutomatedBackupConfig()];

declare 'AutomatedBackupMode',
    as (Int | Str);

declare 'FixedFrequencySchedule',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AutomatedBackupConfig::FixedFrequencySchedule'];

coerce 'FixedFrequencySchedule',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AutomatedBackupConfig::FixedFrequencySchedule'->new($_) };

declare 'RepeatedFixedFrequencySchedule',
    as ArrayRef[FixedFrequencySchedule()];

coerce 'RepeatedFixedFrequencySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AutomatedBackupConfig::FixedFrequencySchedule'->new($_) } @$_ ] };

declare 'MapStringFixedFrequencySchedule',
    as HashRef[FixedFrequencySchedule()];

declare 'BackupCollection',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupCollection'];

coerce 'BackupCollection',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupCollection'->new($_) };

declare 'RepeatedBackupCollection',
    as ArrayRef[BackupCollection()];

coerce 'RepeatedBackupCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupCollection'->new($_) } @$_ ] };

declare 'MapStringBackupCollection',
    as HashRef[BackupCollection()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'BackupType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'BackupFile',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupFile'];

coerce 'BackupFile',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupFile'->new($_) };

declare 'RepeatedBackupFile',
    as ArrayRef[BackupFile()];

coerce 'RepeatedBackupFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::BackupFile'->new($_) } @$_ ] };

declare 'MapStringBackupFile',
    as HashRef[BackupFile()];

declare 'PscServiceAttachment',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscServiceAttachment'];

coerce 'PscServiceAttachment',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscServiceAttachment'->new($_) };

declare 'RepeatedPscServiceAttachment',
    as ArrayRef[PscServiceAttachment()];

coerce 'RepeatedPscServiceAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscServiceAttachment'->new($_) } @$_ ] };

declare 'MapStringPscServiceAttachment',
    as HashRef[PscServiceAttachment()];

declare 'CrossClusterReplicationConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig'];

coerce 'CrossClusterReplicationConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig'->new($_) };

declare 'RepeatedCrossClusterReplicationConfig',
    as ArrayRef[CrossClusterReplicationConfig()];

coerce 'RepeatedCrossClusterReplicationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig'->new($_) } @$_ ] };

declare 'MapStringCrossClusterReplicationConfig',
    as HashRef[CrossClusterReplicationConfig()];

declare 'ClusterRole',
    as (Int | Str);

declare 'RemoteCluster',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig::RemoteCluster'];

coerce 'RemoteCluster',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig::RemoteCluster'->new($_) };

declare 'RepeatedRemoteCluster',
    as ArrayRef[RemoteCluster()];

coerce 'RepeatedRemoteCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig::RemoteCluster'->new($_) } @$_ ] };

declare 'MapStringRemoteCluster',
    as HashRef[RemoteCluster()];

declare 'Membership',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig::Membership'];

coerce 'Membership',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig::Membership'->new($_) };

declare 'RepeatedMembership',
    as ArrayRef[Membership()];

coerce 'RepeatedMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CrossClusterReplicationConfig::Membership'->new($_) } @$_ ] };

declare 'MapStringMembership',
    as HashRef[Membership()];

declare 'ClusterMaintenancePolicy',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterMaintenancePolicy'];

coerce 'ClusterMaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterMaintenancePolicy'->new($_) };

declare 'RepeatedClusterMaintenancePolicy',
    as ArrayRef[ClusterMaintenancePolicy()];

coerce 'RepeatedClusterMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterMaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringClusterMaintenancePolicy',
    as HashRef[ClusterMaintenancePolicy()];

declare 'ClusterWeeklyMaintenanceWindow',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterWeeklyMaintenanceWindow'];

coerce 'ClusterWeeklyMaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterWeeklyMaintenanceWindow'->new($_) };

declare 'RepeatedClusterWeeklyMaintenanceWindow',
    as ArrayRef[ClusterWeeklyMaintenanceWindow()];

coerce 'RepeatedClusterWeeklyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterWeeklyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringClusterWeeklyMaintenanceWindow',
    as HashRef[ClusterWeeklyMaintenanceWindow()];

declare 'ClusterMaintenanceSchedule',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterMaintenanceSchedule'];

coerce 'ClusterMaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterMaintenanceSchedule'->new($_) };

declare 'RepeatedClusterMaintenanceSchedule',
    as ArrayRef[ClusterMaintenanceSchedule()];

coerce 'RepeatedClusterMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterMaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringClusterMaintenanceSchedule',
    as HashRef[ClusterMaintenanceSchedule()];

declare 'PscConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscConfig'];

coerce 'PscConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscConfig'->new($_) };

declare 'RepeatedPscConfig',
    as ArrayRef[PscConfig()];

coerce 'RepeatedPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscConfig'->new($_) } @$_ ] };

declare 'MapStringPscConfig',
    as HashRef[PscConfig()];

declare 'DiscoveryEndpoint',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DiscoveryEndpoint'];

coerce 'DiscoveryEndpoint',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DiscoveryEndpoint'->new($_) };

declare 'RepeatedDiscoveryEndpoint',
    as ArrayRef[DiscoveryEndpoint()];

coerce 'RepeatedDiscoveryEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::DiscoveryEndpoint'->new($_) } @$_ ] };

declare 'MapStringDiscoveryEndpoint',
    as HashRef[DiscoveryEndpoint()];

declare 'PscConnection',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscConnection'];

coerce 'PscConnection',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscConnection'->new($_) };

declare 'RepeatedPscConnection',
    as ArrayRef[PscConnection()];

coerce 'RepeatedPscConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscConnection'->new($_) } @$_ ] };

declare 'MapStringPscConnection',
    as HashRef[PscConnection()];

declare 'ClusterEndpoint',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterEndpoint'];

coerce 'ClusterEndpoint',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterEndpoint'->new($_) };

declare 'RepeatedClusterEndpoint',
    as ArrayRef[ClusterEndpoint()];

coerce 'RepeatedClusterEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterEndpoint'->new($_) } @$_ ] };

declare 'MapStringClusterEndpoint',
    as HashRef[ClusterEndpoint()];

declare 'ConnectionDetail',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ConnectionDetail'];

coerce 'ConnectionDetail',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ConnectionDetail'->new($_) };

declare 'RepeatedConnectionDetail',
    as ArrayRef[ConnectionDetail()];

coerce 'RepeatedConnectionDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ConnectionDetail'->new($_) } @$_ ] };

declare 'MapStringConnectionDetail',
    as HashRef[ConnectionDetail()];

declare 'PscAutoConnection',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscAutoConnection'];

coerce 'PscAutoConnection',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscAutoConnection'->new($_) };

declare 'RepeatedPscAutoConnection',
    as ArrayRef[PscAutoConnection()];

coerce 'RepeatedPscAutoConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::PscAutoConnection'->new($_) } @$_ ] };

declare 'MapStringPscAutoConnection',
    as HashRef[PscAutoConnection()];

declare 'SharedRegionalCertificateAuthority',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority'];

coerce 'SharedRegionalCertificateAuthority',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority'->new($_) };

declare 'RepeatedSharedRegionalCertificateAuthority',
    as ArrayRef[SharedRegionalCertificateAuthority()];

coerce 'RepeatedSharedRegionalCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringSharedRegionalCertificateAuthority',
    as HashRef[SharedRegionalCertificateAuthority()];

declare 'RegionalManagedCertificateAuthority',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority'];

coerce 'RegionalManagedCertificateAuthority',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority'->new($_) };

declare 'RepeatedRegionalManagedCertificateAuthority',
    as ArrayRef[RegionalManagedCertificateAuthority()];

coerce 'RepeatedRegionalManagedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringRegionalManagedCertificateAuthority',
    as HashRef[RegionalManagedCertificateAuthority()];

declare 'RegionalCertChain',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority::RegionalCertChain'];

coerce 'RegionalCertChain',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority::RegionalCertChain'->new($_) };

declare 'RepeatedRegionalCertChain',
    as ArrayRef[RegionalCertChain()];

coerce 'RepeatedRegionalCertChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority::RegionalCertChain'->new($_) } @$_ ] };

declare 'MapStringRegionalCertChain',
    as HashRef[RegionalCertChain()];

declare 'GetSharedRegionalCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetSharedRegionalCertificateAuthorityRequest'];

coerce 'GetSharedRegionalCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetSharedRegionalCertificateAuthorityRequest'->new($_) };

declare 'RepeatedGetSharedRegionalCertificateAuthorityRequest',
    as ArrayRef[GetSharedRegionalCertificateAuthorityRequest()];

coerce 'RepeatedGetSharedRegionalCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::GetSharedRegionalCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringGetSharedRegionalCertificateAuthorityRequest',
    as HashRef[GetSharedRegionalCertificateAuthorityRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'TokenAuthUser',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::TokenAuthUser'];

coerce 'TokenAuthUser',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::TokenAuthUser'->new($_) };

declare 'RepeatedTokenAuthUser',
    as ArrayRef[TokenAuthUser()];

coerce 'RepeatedTokenAuthUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::TokenAuthUser'->new($_) } @$_ ] };

declare 'MapStringTokenAuthUser',
    as HashRef[TokenAuthUser()];

declare 'State',
    as (Int | Str);

declare 'AuthToken',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AuthToken'];

coerce 'AuthToken',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AuthToken'->new($_) };

declare 'RepeatedAuthToken',
    as ArrayRef[AuthToken()];

coerce 'RepeatedAuthToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::AuthToken'->new($_) } @$_ ] };

declare 'MapStringAuthToken',
    as HashRef[AuthToken()];

declare 'State',
    as (Int | Str);

declare 'CertificateAuthority',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority'];

coerce 'CertificateAuthority',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority'->new($_) };

declare 'RepeatedCertificateAuthority',
    as ArrayRef[CertificateAuthority()];

coerce 'RepeatedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthority',
    as HashRef[CertificateAuthority()];

declare 'ManagedCertificateAuthority',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority::ManagedCertificateAuthority'];

coerce 'ManagedCertificateAuthority',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority::ManagedCertificateAuthority'->new($_) };

declare 'RepeatedManagedCertificateAuthority',
    as ArrayRef[ManagedCertificateAuthority()];

coerce 'RepeatedManagedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority::ManagedCertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringManagedCertificateAuthority',
    as HashRef[ManagedCertificateAuthority()];

declare 'CertChain',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority::ManagedCertificateAuthority::CertChain'];

coerce 'CertChain',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority::ManagedCertificateAuthority::CertChain'->new($_) };

declare 'RepeatedCertChain',
    as ArrayRef[CertChain()];

coerce 'RepeatedCertChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::CertificateAuthority::ManagedCertificateAuthority::CertChain'->new($_) } @$_ ] };

declare 'MapStringCertChain',
    as HashRef[CertChain()];

declare 'ClusterPersistenceConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig'];

coerce 'ClusterPersistenceConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig'->new($_) };

declare 'RepeatedClusterPersistenceConfig',
    as ArrayRef[ClusterPersistenceConfig()];

coerce 'RepeatedClusterPersistenceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig'->new($_) } @$_ ] };

declare 'MapStringClusterPersistenceConfig',
    as HashRef[ClusterPersistenceConfig()];

declare 'PersistenceMode',
    as (Int | Str);

declare 'RDBConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig::RDBConfig'];

coerce 'RDBConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig::RDBConfig'->new($_) };

declare 'RepeatedRDBConfig',
    as ArrayRef[RDBConfig()];

coerce 'RepeatedRDBConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig::RDBConfig'->new($_) } @$_ ] };

declare 'MapStringRDBConfig',
    as HashRef[RDBConfig()];

declare 'SnapshotPeriod',
    as (Int | Str);

declare 'AOFConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig::AOFConfig'];

coerce 'AOFConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig::AOFConfig'->new($_) };

declare 'RepeatedAOFConfig',
    as ArrayRef[AOFConfig()];

coerce 'RepeatedAOFConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ClusterPersistenceConfig::AOFConfig'->new($_) } @$_ ] };

declare 'MapStringAOFConfig',
    as HashRef[AOFConfig()];

declare 'AppendFsync',
    as (Int | Str);

declare 'ZoneDistributionConfig',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ZoneDistributionConfig'];

coerce 'ZoneDistributionConfig',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ZoneDistributionConfig'->new($_) };

declare 'RepeatedZoneDistributionConfig',
    as ArrayRef[ZoneDistributionConfig()];

coerce 'RepeatedZoneDistributionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::ZoneDistributionConfig'->new($_) } @$_ ] };

declare 'MapStringZoneDistributionConfig',
    as HashRef[ZoneDistributionConfig()];

declare 'ZoneDistributionMode',
    as (Int | Str);

declare 'RescheduleClusterMaintenanceRequest',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::RescheduleClusterMaintenanceRequest'];

coerce 'RescheduleClusterMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::RescheduleClusterMaintenanceRequest'->new($_) };

declare 'RepeatedRescheduleClusterMaintenanceRequest',
    as ArrayRef[RescheduleClusterMaintenanceRequest()];

coerce 'RepeatedRescheduleClusterMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::RescheduleClusterMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringRescheduleClusterMaintenanceRequest',
    as HashRef[RescheduleClusterMaintenanceRequest()];

declare 'RescheduleType',
    as (Int | Str);

declare 'EncryptionInfo',
    as InstanceOf['Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::EncryptionInfo'];

coerce 'EncryptionInfo',
    from HashRef, via { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::EncryptionInfo'->new($_) };

declare 'RepeatedEncryptionInfo',
    as ArrayRef[EncryptionInfo()];

coerce 'RepeatedEncryptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::EncryptionInfo'->new($_) } @$_ ] };

declare 'MapStringEncryptionInfo',
    as HashRef[EncryptionInfo()];

declare 'Type',
    as (Int | Str);

declare 'KmsKeyState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Redis::Cluster::V1beta1::CloudRedisCluster::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
