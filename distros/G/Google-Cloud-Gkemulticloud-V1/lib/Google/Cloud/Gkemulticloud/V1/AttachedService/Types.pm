package Google::Cloud::Gkemulticloud::V1::AttachedService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateAttachedClusterInstallManifestRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterInstallManifestRequest'];

coerce 'GenerateAttachedClusterInstallManifestRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterInstallManifestRequest'->new($_) };

declare 'RepeatedGenerateAttachedClusterInstallManifestRequest',
    as ArrayRef[GenerateAttachedClusterInstallManifestRequest()];

coerce 'RepeatedGenerateAttachedClusterInstallManifestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterInstallManifestRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAttachedClusterInstallManifestRequest',
    as HashRef[GenerateAttachedClusterInstallManifestRequest()];

declare 'GenerateAttachedClusterInstallManifestResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterInstallManifestResponse'];

coerce 'GenerateAttachedClusterInstallManifestResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterInstallManifestResponse'->new($_) };

declare 'RepeatedGenerateAttachedClusterInstallManifestResponse',
    as ArrayRef[GenerateAttachedClusterInstallManifestResponse()];

coerce 'RepeatedGenerateAttachedClusterInstallManifestResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterInstallManifestResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAttachedClusterInstallManifestResponse',
    as HashRef[GenerateAttachedClusterInstallManifestResponse()];

declare 'CreateAttachedClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::CreateAttachedClusterRequest'];

coerce 'CreateAttachedClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::CreateAttachedClusterRequest'->new($_) };

declare 'RepeatedCreateAttachedClusterRequest',
    as ArrayRef[CreateAttachedClusterRequest()];

coerce 'RepeatedCreateAttachedClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::CreateAttachedClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAttachedClusterRequest',
    as HashRef[CreateAttachedClusterRequest()];

declare 'ImportAttachedClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::ImportAttachedClusterRequest'];

coerce 'ImportAttachedClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::ImportAttachedClusterRequest'->new($_) };

declare 'RepeatedImportAttachedClusterRequest',
    as ArrayRef[ImportAttachedClusterRequest()];

coerce 'RepeatedImportAttachedClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::ImportAttachedClusterRequest'->new($_) } @$_ ] };

declare 'MapStringImportAttachedClusterRequest',
    as HashRef[ImportAttachedClusterRequest()];

declare 'UpdateAttachedClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::UpdateAttachedClusterRequest'];

coerce 'UpdateAttachedClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::UpdateAttachedClusterRequest'->new($_) };

declare 'RepeatedUpdateAttachedClusterRequest',
    as ArrayRef[UpdateAttachedClusterRequest()];

coerce 'RepeatedUpdateAttachedClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::UpdateAttachedClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAttachedClusterRequest',
    as HashRef[UpdateAttachedClusterRequest()];

declare 'GetAttachedClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::GetAttachedClusterRequest'];

coerce 'GetAttachedClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GetAttachedClusterRequest'->new($_) };

declare 'RepeatedGetAttachedClusterRequest',
    as ArrayRef[GetAttachedClusterRequest()];

coerce 'RepeatedGetAttachedClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GetAttachedClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttachedClusterRequest',
    as HashRef[GetAttachedClusterRequest()];

declare 'ListAttachedClustersRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::ListAttachedClustersRequest'];

coerce 'ListAttachedClustersRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::ListAttachedClustersRequest'->new($_) };

declare 'RepeatedListAttachedClustersRequest',
    as ArrayRef[ListAttachedClustersRequest()];

coerce 'RepeatedListAttachedClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::ListAttachedClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListAttachedClustersRequest',
    as HashRef[ListAttachedClustersRequest()];

declare 'ListAttachedClustersResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::ListAttachedClustersResponse'];

coerce 'ListAttachedClustersResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::ListAttachedClustersResponse'->new($_) };

declare 'RepeatedListAttachedClustersResponse',
    as ArrayRef[ListAttachedClustersResponse()];

coerce 'RepeatedListAttachedClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::ListAttachedClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListAttachedClustersResponse',
    as HashRef[ListAttachedClustersResponse()];

declare 'DeleteAttachedClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::DeleteAttachedClusterRequest'];

coerce 'DeleteAttachedClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::DeleteAttachedClusterRequest'->new($_) };

declare 'RepeatedDeleteAttachedClusterRequest',
    as ArrayRef[DeleteAttachedClusterRequest()];

coerce 'RepeatedDeleteAttachedClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::DeleteAttachedClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAttachedClusterRequest',
    as HashRef[DeleteAttachedClusterRequest()];

declare 'GetAttachedServerConfigRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::GetAttachedServerConfigRequest'];

coerce 'GetAttachedServerConfigRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GetAttachedServerConfigRequest'->new($_) };

declare 'RepeatedGetAttachedServerConfigRequest',
    as ArrayRef[GetAttachedServerConfigRequest()];

coerce 'RepeatedGetAttachedServerConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GetAttachedServerConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttachedServerConfigRequest',
    as HashRef[GetAttachedServerConfigRequest()];

declare 'GenerateAttachedClusterAgentTokenRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterAgentTokenRequest'];

coerce 'GenerateAttachedClusterAgentTokenRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterAgentTokenRequest'->new($_) };

declare 'RepeatedGenerateAttachedClusterAgentTokenRequest',
    as ArrayRef[GenerateAttachedClusterAgentTokenRequest()];

coerce 'RepeatedGenerateAttachedClusterAgentTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterAgentTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAttachedClusterAgentTokenRequest',
    as HashRef[GenerateAttachedClusterAgentTokenRequest()];

declare 'GenerateAttachedClusterAgentTokenResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterAgentTokenResponse'];

coerce 'GenerateAttachedClusterAgentTokenResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterAgentTokenResponse'->new($_) };

declare 'RepeatedGenerateAttachedClusterAgentTokenResponse',
    as ArrayRef[GenerateAttachedClusterAgentTokenResponse()];

coerce 'RepeatedGenerateAttachedClusterAgentTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedService::GenerateAttachedClusterAgentTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAttachedClusterAgentTokenResponse',
    as HashRef[GenerateAttachedClusterAgentTokenResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AttachedService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
