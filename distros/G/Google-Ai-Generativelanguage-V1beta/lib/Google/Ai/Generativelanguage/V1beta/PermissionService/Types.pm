package Google::Ai::Generativelanguage::V1beta::PermissionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreatePermissionRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest'];

coerce 'CreatePermissionRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest'->new($_) };

declare 'RepeatedCreatePermissionRequest',
    as ArrayRef[CreatePermissionRequest()];

coerce 'RepeatedCreatePermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePermissionRequest',
    as HashRef[CreatePermissionRequest()];

declare 'GetPermissionRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::GetPermissionRequest'];

coerce 'GetPermissionRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::GetPermissionRequest'->new($_) };

declare 'RepeatedGetPermissionRequest',
    as ArrayRef[GetPermissionRequest()];

coerce 'RepeatedGetPermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::GetPermissionRequest'->new($_) } @$_ ] };

declare 'MapStringGetPermissionRequest',
    as HashRef[GetPermissionRequest()];

declare 'ListPermissionsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsRequest'];

coerce 'ListPermissionsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsRequest'->new($_) };

declare 'RepeatedListPermissionsRequest',
    as ArrayRef[ListPermissionsRequest()];

coerce 'RepeatedListPermissionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPermissionsRequest',
    as HashRef[ListPermissionsRequest()];

declare 'ListPermissionsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsResponse'];

coerce 'ListPermissionsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsResponse'->new($_) };

declare 'RepeatedListPermissionsResponse',
    as ArrayRef[ListPermissionsResponse()];

coerce 'RepeatedListPermissionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPermissionsResponse',
    as HashRef[ListPermissionsResponse()];

declare 'UpdatePermissionRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::UpdatePermissionRequest'];

coerce 'UpdatePermissionRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::UpdatePermissionRequest'->new($_) };

declare 'RepeatedUpdatePermissionRequest',
    as ArrayRef[UpdatePermissionRequest()];

coerce 'RepeatedUpdatePermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::UpdatePermissionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePermissionRequest',
    as HashRef[UpdatePermissionRequest()];

declare 'DeletePermissionRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::DeletePermissionRequest'];

coerce 'DeletePermissionRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::DeletePermissionRequest'->new($_) };

declare 'RepeatedDeletePermissionRequest',
    as ArrayRef[DeletePermissionRequest()];

coerce 'RepeatedDeletePermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::DeletePermissionRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePermissionRequest',
    as HashRef[DeletePermissionRequest()];

declare 'TransferOwnershipRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest'];

coerce 'TransferOwnershipRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest'->new($_) };

declare 'RepeatedTransferOwnershipRequest',
    as ArrayRef[TransferOwnershipRequest()];

coerce 'RepeatedTransferOwnershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest'->new($_) } @$_ ] };

declare 'MapStringTransferOwnershipRequest',
    as HashRef[TransferOwnershipRequest()];

declare 'TransferOwnershipResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse'];

coerce 'TransferOwnershipResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse'->new($_) };

declare 'RepeatedTransferOwnershipResponse',
    as ArrayRef[TransferOwnershipResponse()];

coerce 'RepeatedTransferOwnershipResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse'->new($_) } @$_ ] };

declare 'MapStringTransferOwnershipResponse',
    as HashRef[TransferOwnershipResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PermissionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
