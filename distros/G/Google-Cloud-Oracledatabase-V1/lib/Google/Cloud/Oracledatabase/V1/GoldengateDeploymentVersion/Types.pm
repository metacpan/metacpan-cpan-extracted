package Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateDeploymentVersion',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion'];

coerce 'GoldengateDeploymentVersion',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion'->new($_) };

declare 'RepeatedGoldengateDeploymentVersion',
    as ArrayRef[GoldengateDeploymentVersion()];

coerce 'RepeatedGoldengateDeploymentVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeploymentVersion',
    as HashRef[GoldengateDeploymentVersion()];

declare 'GoldengateDeploymentVersionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersionProperties'];

coerce 'GoldengateDeploymentVersionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersionProperties'->new($_) };

declare 'RepeatedGoldengateDeploymentVersionProperties',
    as ArrayRef[GoldengateDeploymentVersionProperties()];

coerce 'RepeatedGoldengateDeploymentVersionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeploymentVersionProperties',
    as HashRef[GoldengateDeploymentVersionProperties()];

declare 'DeploymentType',
    as (Int | Str);

declare 'DeploymentReleaseType',
    as (Int | Str);

declare 'ListGoldengateDeploymentVersionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsRequest'];

coerce 'ListGoldengateDeploymentVersionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsRequest'->new($_) };

declare 'RepeatedListGoldengateDeploymentVersionsRequest',
    as ArrayRef[ListGoldengateDeploymentVersionsRequest()];

coerce 'RepeatedListGoldengateDeploymentVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentVersionsRequest',
    as HashRef[ListGoldengateDeploymentVersionsRequest()];

declare 'ListGoldengateDeploymentVersionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsResponse'];

coerce 'ListGoldengateDeploymentVersionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsResponse'->new($_) };

declare 'RepeatedListGoldengateDeploymentVersionsResponse',
    as ArrayRef[ListGoldengateDeploymentVersionsResponse()];

coerce 'RepeatedListGoldengateDeploymentVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentVersionsResponse',
    as HashRef[ListGoldengateDeploymentVersionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
