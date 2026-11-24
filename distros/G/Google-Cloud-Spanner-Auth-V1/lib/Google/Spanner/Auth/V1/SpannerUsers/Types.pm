package Google::Spanner::Auth::V1::SpannerUsers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'User',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::User'];

coerce 'User',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'State',
    as (Int | Str);

declare 'Role',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::Role'];

coerce 'Role',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::Role'->new($_) };

declare 'RepeatedRole',
    as ArrayRef[Role()];

coerce 'RepeatedRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::Role'->new($_) } @$_ ] };

declare 'MapStringRole',
    as HashRef[Role()];

declare 'CreateUserRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest'];

coerce 'CreateUserRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest'->new($_) };

declare 'RepeatedCreateUserRequest',
    as ArrayRef[CreateUserRequest()];

coerce 'RepeatedCreateUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUserRequest',
    as HashRef[CreateUserRequest()];

declare 'CreateUserResponse',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse'];

coerce 'CreateUserResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse'->new($_) };

declare 'RepeatedCreateUserResponse',
    as ArrayRef[CreateUserResponse()];

coerce 'RepeatedCreateUserResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse'->new($_) } @$_ ] };

declare 'MapStringCreateUserResponse',
    as HashRef[CreateUserResponse()];

declare 'UpdateUserRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest'];

coerce 'UpdateUserRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest'->new($_) };

declare 'RepeatedUpdateUserRequest',
    as ArrayRef[UpdateUserRequest()];

coerce 'RepeatedUpdateUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserRequest',
    as HashRef[UpdateUserRequest()];

declare 'GetUserRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest'];

coerce 'GetUserRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest'->new($_) };

declare 'RepeatedGetUserRequest',
    as ArrayRef[GetUserRequest()];

coerce 'RepeatedGetUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserRequest',
    as HashRef[GetUserRequest()];

declare 'ListUsersRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest'];

coerce 'ListUsersRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest'->new($_) };

declare 'RepeatedListUsersRequest',
    as ArrayRef[ListUsersRequest()];

coerce 'RepeatedListUsersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest'->new($_) } @$_ ] };

declare 'MapStringListUsersRequest',
    as HashRef[ListUsersRequest()];

declare 'ListUsersResponse',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse'];

coerce 'ListUsersResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse'->new($_) };

declare 'RepeatedListUsersResponse',
    as ArrayRef[ListUsersResponse()];

coerce 'RepeatedListUsersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse'->new($_) } @$_ ] };

declare 'MapStringListUsersResponse',
    as HashRef[ListUsersResponse()];

declare 'DeleteUserRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest'];

coerce 'DeleteUserRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest'->new($_) };

declare 'RepeatedDeleteUserRequest',
    as ArrayRef[DeleteUserRequest()];

coerce 'RepeatedDeleteUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserRequest',
    as HashRef[DeleteUserRequest()];

declare 'ListRolesRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest'];

coerce 'ListRolesRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest'->new($_) };

declare 'RepeatedListRolesRequest',
    as ArrayRef[ListRolesRequest()];

coerce 'RepeatedListRolesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest'->new($_) } @$_ ] };

declare 'MapStringListRolesRequest',
    as HashRef[ListRolesRequest()];

declare 'ListRolesResponse',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse'];

coerce 'ListRolesResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse'->new($_) };

declare 'RepeatedListRolesResponse',
    as ArrayRef[ListRolesResponse()];

coerce 'RepeatedListRolesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse'->new($_) } @$_ ] };

declare 'MapStringListRolesResponse',
    as HashRef[ListRolesResponse()];

declare 'GetRoleRequest',
    as InstanceOf['Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest'];

coerce 'GetRoleRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest'->new($_) };

declare 'RepeatedGetRoleRequest',
    as ArrayRef[GetRoleRequest()];

coerce 'RepeatedGetRoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest'->new($_) } @$_ ] };

declare 'MapStringGetRoleRequest',
    as HashRef[GetRoleRequest()];

1;

__END__

=head1 NAME

Google::Spanner::Auth::V1::SpannerUsers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
