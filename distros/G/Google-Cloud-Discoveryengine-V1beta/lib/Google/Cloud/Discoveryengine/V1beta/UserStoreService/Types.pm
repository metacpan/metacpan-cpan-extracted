package Google::Cloud::Discoveryengine::V1beta::UserStoreService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetUserStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest'];

coerce 'GetUserStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest'->new($_) };

declare 'RepeatedGetUserStoreRequest',
    as ArrayRef[GetUserStoreRequest()];

coerce 'RepeatedGetUserStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserStoreRequest',
    as HashRef[GetUserStoreRequest()];

declare 'UpdateUserStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserStoreService::UpdateUserStoreRequest'];

coerce 'UpdateUserStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserStoreService::UpdateUserStoreRequest'->new($_) };

declare 'RepeatedUpdateUserStoreRequest',
    as ArrayRef[UpdateUserStoreRequest()];

coerce 'RepeatedUpdateUserStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserStoreService::UpdateUserStoreRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserStoreRequest',
    as HashRef[UpdateUserStoreRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserStoreService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
