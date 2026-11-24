package Google::Chromeos::Moblab::V1beta1::BuildService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FindMostStableBuildRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest'];

coerce 'FindMostStableBuildRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest'->new($_) };

declare 'RepeatedFindMostStableBuildRequest',
    as ArrayRef[FindMostStableBuildRequest()];

coerce 'RepeatedFindMostStableBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest'->new($_) } @$_ ] };

declare 'MapStringFindMostStableBuildRequest',
    as HashRef[FindMostStableBuildRequest()];

declare 'FindMostStableBuildResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildResponse'];

coerce 'FindMostStableBuildResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildResponse'->new($_) };

declare 'RepeatedFindMostStableBuildResponse',
    as ArrayRef[FindMostStableBuildResponse()];

coerce 'RepeatedFindMostStableBuildResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildResponse'->new($_) } @$_ ] };

declare 'MapStringFindMostStableBuildResponse',
    as HashRef[FindMostStableBuildResponse()];

declare 'ListBuildTargetsRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest'];

coerce 'ListBuildTargetsRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest'->new($_) };

declare 'RepeatedListBuildTargetsRequest',
    as ArrayRef[ListBuildTargetsRequest()];

coerce 'RepeatedListBuildTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringListBuildTargetsRequest',
    as HashRef[ListBuildTargetsRequest()];

declare 'ListBuildTargetsResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse'];

coerce 'ListBuildTargetsResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse'->new($_) };

declare 'RepeatedListBuildTargetsResponse',
    as ArrayRef[ListBuildTargetsResponse()];

coerce 'RepeatedListBuildTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringListBuildTargetsResponse',
    as HashRef[ListBuildTargetsResponse()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'ListBuildsRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsRequest'];

coerce 'ListBuildsRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsRequest'->new($_) };

declare 'RepeatedListBuildsRequest',
    as ArrayRef[ListBuildsRequest()];

coerce 'RepeatedListBuildsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsRequest'->new($_) } @$_ ] };

declare 'MapStringListBuildsRequest',
    as HashRef[ListBuildsRequest()];

declare 'ListBuildsResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsResponse'];

coerce 'ListBuildsResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsResponse'->new($_) };

declare 'RepeatedListBuildsResponse',
    as ArrayRef[ListBuildsResponse()];

coerce 'RepeatedListBuildsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsResponse'->new($_) } @$_ ] };

declare 'MapStringListBuildsResponse',
    as HashRef[ListBuildsResponse()];

declare 'CheckBuildStageStatusRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusRequest'];

coerce 'CheckBuildStageStatusRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusRequest'->new($_) };

declare 'RepeatedCheckBuildStageStatusRequest',
    as ArrayRef[CheckBuildStageStatusRequest()];

coerce 'RepeatedCheckBuildStageStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusRequest'->new($_) } @$_ ] };

declare 'MapStringCheckBuildStageStatusRequest',
    as HashRef[CheckBuildStageStatusRequest()];

declare 'CheckBuildStageStatusResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusResponse'];

coerce 'CheckBuildStageStatusResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusResponse'->new($_) };

declare 'RepeatedCheckBuildStageStatusResponse',
    as ArrayRef[CheckBuildStageStatusResponse()];

coerce 'RepeatedCheckBuildStageStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusResponse'->new($_) } @$_ ] };

declare 'MapStringCheckBuildStageStatusResponse',
    as HashRef[CheckBuildStageStatusResponse()];

declare 'StageBuildRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildRequest'];

coerce 'StageBuildRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildRequest'->new($_) };

declare 'RepeatedStageBuildRequest',
    as ArrayRef[StageBuildRequest()];

coerce 'RepeatedStageBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildRequest'->new($_) } @$_ ] };

declare 'MapStringStageBuildRequest',
    as HashRef[StageBuildRequest()];

declare 'StageBuildResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildResponse'];

coerce 'StageBuildResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildResponse'->new($_) };

declare 'RepeatedStageBuildResponse',
    as ArrayRef[StageBuildResponse()];

coerce 'RepeatedStageBuildResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildResponse'->new($_) } @$_ ] };

declare 'MapStringStageBuildResponse',
    as HashRef[StageBuildResponse()];

declare 'StageBuildMetadata',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildMetadata'];

coerce 'StageBuildMetadata',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildMetadata'->new($_) };

declare 'RepeatedStageBuildMetadata',
    as ArrayRef[StageBuildMetadata()];

coerce 'RepeatedStageBuildMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildMetadata'->new($_) } @$_ ] };

declare 'MapStringStageBuildMetadata',
    as HashRef[StageBuildMetadata()];

1;

__END__

=head1 NAME

Google::Chromeos::Moblab::V1beta1::BuildService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
