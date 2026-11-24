package Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateDeploymentType',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType'];

coerce 'GoldengateDeploymentType',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType'->new($_) };

declare 'RepeatedGoldengateDeploymentType',
    as ArrayRef[GoldengateDeploymentType()];

coerce 'RepeatedGoldengateDeploymentType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeploymentType',
    as HashRef[GoldengateDeploymentType()];

declare 'DeploymentType',
    as (Int | Str);

declare 'DeploymentCategory',
    as (Int | Str);

declare 'ListGoldengateDeploymentTypesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesRequest'];

coerce 'ListGoldengateDeploymentTypesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesRequest'->new($_) };

declare 'RepeatedListGoldengateDeploymentTypesRequest',
    as ArrayRef[ListGoldengateDeploymentTypesRequest()];

coerce 'RepeatedListGoldengateDeploymentTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentTypesRequest',
    as HashRef[ListGoldengateDeploymentTypesRequest()];

declare 'ListGoldengateDeploymentTypesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesResponse'];

coerce 'ListGoldengateDeploymentTypesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesResponse'->new($_) };

declare 'RepeatedListGoldengateDeploymentTypesResponse',
    as ArrayRef[ListGoldengateDeploymentTypesResponse()];

coerce 'RepeatedListGoldengateDeploymentTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentTypesResponse',
    as HashRef[ListGoldengateDeploymentTypesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
