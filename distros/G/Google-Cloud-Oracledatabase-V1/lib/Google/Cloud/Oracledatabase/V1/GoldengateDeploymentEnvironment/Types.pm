package Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateDeploymentEnvironment',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment'];

coerce 'GoldengateDeploymentEnvironment',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment'->new($_) };

declare 'RepeatedGoldengateDeploymentEnvironment',
    as ArrayRef[GoldengateDeploymentEnvironment()];

coerce 'RepeatedGoldengateDeploymentEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeploymentEnvironment',
    as HashRef[GoldengateDeploymentEnvironment()];

declare 'DeploymentCategory',
    as (Int | Str);

declare 'DeploymentEnvironmentType',
    as (Int | Str);

declare 'ListGoldengateDeploymentEnvironmentsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsRequest'];

coerce 'ListGoldengateDeploymentEnvironmentsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsRequest'->new($_) };

declare 'RepeatedListGoldengateDeploymentEnvironmentsRequest',
    as ArrayRef[ListGoldengateDeploymentEnvironmentsRequest()];

coerce 'RepeatedListGoldengateDeploymentEnvironmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentEnvironmentsRequest',
    as HashRef[ListGoldengateDeploymentEnvironmentsRequest()];

declare 'ListGoldengateDeploymentEnvironmentsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsResponse'];

coerce 'ListGoldengateDeploymentEnvironmentsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsResponse'->new($_) };

declare 'RepeatedListGoldengateDeploymentEnvironmentsResponse',
    as ArrayRef[ListGoldengateDeploymentEnvironmentsResponse()];

coerce 'RepeatedListGoldengateDeploymentEnvironmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentEnvironmentsResponse',
    as HashRef[ListGoldengateDeploymentEnvironmentsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
