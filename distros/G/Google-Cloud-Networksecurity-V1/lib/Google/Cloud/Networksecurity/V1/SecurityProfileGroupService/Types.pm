package Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListSecurityProfileGroupsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsRequest'];

coerce 'ListSecurityProfileGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsRequest'->new($_) };

declare 'RepeatedListSecurityProfileGroupsRequest',
    as ArrayRef[ListSecurityProfileGroupsRequest()];

coerce 'RepeatedListSecurityProfileGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListSecurityProfileGroupsRequest',
    as HashRef[ListSecurityProfileGroupsRequest()];

declare 'ListSecurityProfileGroupsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse'];

coerce 'ListSecurityProfileGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse'->new($_) };

declare 'RepeatedListSecurityProfileGroupsResponse',
    as ArrayRef[ListSecurityProfileGroupsResponse()];

coerce 'RepeatedListSecurityProfileGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListSecurityProfileGroupsResponse',
    as HashRef[ListSecurityProfileGroupsResponse()];

declare 'GetSecurityProfileGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::GetSecurityProfileGroupRequest'];

coerce 'GetSecurityProfileGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::GetSecurityProfileGroupRequest'->new($_) };

declare 'RepeatedGetSecurityProfileGroupRequest',
    as ArrayRef[GetSecurityProfileGroupRequest()];

coerce 'RepeatedGetSecurityProfileGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::GetSecurityProfileGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecurityProfileGroupRequest',
    as HashRef[GetSecurityProfileGroupRequest()];

declare 'CreateSecurityProfileGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::CreateSecurityProfileGroupRequest'];

coerce 'CreateSecurityProfileGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::CreateSecurityProfileGroupRequest'->new($_) };

declare 'RepeatedCreateSecurityProfileGroupRequest',
    as ArrayRef[CreateSecurityProfileGroupRequest()];

coerce 'RepeatedCreateSecurityProfileGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::CreateSecurityProfileGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecurityProfileGroupRequest',
    as HashRef[CreateSecurityProfileGroupRequest()];

declare 'UpdateSecurityProfileGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::UpdateSecurityProfileGroupRequest'];

coerce 'UpdateSecurityProfileGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::UpdateSecurityProfileGroupRequest'->new($_) };

declare 'RepeatedUpdateSecurityProfileGroupRequest',
    as ArrayRef[UpdateSecurityProfileGroupRequest()];

coerce 'RepeatedUpdateSecurityProfileGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::UpdateSecurityProfileGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityProfileGroupRequest',
    as HashRef[UpdateSecurityProfileGroupRequest()];

declare 'DeleteSecurityProfileGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::DeleteSecurityProfileGroupRequest'];

coerce 'DeleteSecurityProfileGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::DeleteSecurityProfileGroupRequest'->new($_) };

declare 'RepeatedDeleteSecurityProfileGroupRequest',
    as ArrayRef[DeleteSecurityProfileGroupRequest()];

coerce 'RepeatedDeleteSecurityProfileGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::DeleteSecurityProfileGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSecurityProfileGroupRequest',
    as HashRef[DeleteSecurityProfileGroupRequest()];

declare 'ListSecurityProfilesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfilesRequest'];

coerce 'ListSecurityProfilesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfilesRequest'->new($_) };

declare 'RepeatedListSecurityProfilesRequest',
    as ArrayRef[ListSecurityProfilesRequest()];

coerce 'RepeatedListSecurityProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListSecurityProfilesRequest',
    as HashRef[ListSecurityProfilesRequest()];

declare 'ListSecurityProfilesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfilesResponse'];

coerce 'ListSecurityProfilesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfilesResponse'->new($_) };

declare 'RepeatedListSecurityProfilesResponse',
    as ArrayRef[ListSecurityProfilesResponse()];

coerce 'RepeatedListSecurityProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListSecurityProfilesResponse',
    as HashRef[ListSecurityProfilesResponse()];

declare 'GetSecurityProfileRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::GetSecurityProfileRequest'];

coerce 'GetSecurityProfileRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::GetSecurityProfileRequest'->new($_) };

declare 'RepeatedGetSecurityProfileRequest',
    as ArrayRef[GetSecurityProfileRequest()];

coerce 'RepeatedGetSecurityProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::GetSecurityProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecurityProfileRequest',
    as HashRef[GetSecurityProfileRequest()];

declare 'CreateSecurityProfileRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::CreateSecurityProfileRequest'];

coerce 'CreateSecurityProfileRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::CreateSecurityProfileRequest'->new($_) };

declare 'RepeatedCreateSecurityProfileRequest',
    as ArrayRef[CreateSecurityProfileRequest()];

coerce 'RepeatedCreateSecurityProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::CreateSecurityProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecurityProfileRequest',
    as HashRef[CreateSecurityProfileRequest()];

declare 'UpdateSecurityProfileRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::UpdateSecurityProfileRequest'];

coerce 'UpdateSecurityProfileRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::UpdateSecurityProfileRequest'->new($_) };

declare 'RepeatedUpdateSecurityProfileRequest',
    as ArrayRef[UpdateSecurityProfileRequest()];

coerce 'RepeatedUpdateSecurityProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::UpdateSecurityProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityProfileRequest',
    as HashRef[UpdateSecurityProfileRequest()];

declare 'DeleteSecurityProfileRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::DeleteSecurityProfileRequest'];

coerce 'DeleteSecurityProfileRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::DeleteSecurityProfileRequest'->new($_) };

declare 'RepeatedDeleteSecurityProfileRequest',
    as ArrayRef[DeleteSecurityProfileRequest()];

coerce 'RepeatedDeleteSecurityProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::DeleteSecurityProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSecurityProfileRequest',
    as HashRef[DeleteSecurityProfileRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
