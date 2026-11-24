package Google::Cloud::Securitycenter::V1::OrganizationSettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OrganizationSettings',
    as InstanceOf['Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings'];

coerce 'OrganizationSettings',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings'->new($_) };

declare 'RepeatedOrganizationSettings',
    as ArrayRef[OrganizationSettings()];

coerce 'RepeatedOrganizationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings'->new($_) } @$_ ] };

declare 'MapStringOrganizationSettings',
    as HashRef[OrganizationSettings()];

declare 'AssetDiscoveryConfig',
    as InstanceOf['Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings::AssetDiscoveryConfig'];

coerce 'AssetDiscoveryConfig',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings::AssetDiscoveryConfig'->new($_) };

declare 'RepeatedAssetDiscoveryConfig',
    as ArrayRef[AssetDiscoveryConfig()];

coerce 'RepeatedAssetDiscoveryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings::AssetDiscoveryConfig'->new($_) } @$_ ] };

declare 'MapStringAssetDiscoveryConfig',
    as HashRef[AssetDiscoveryConfig()];

declare 'InclusionMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::OrganizationSettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
