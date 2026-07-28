package Google::Cloud::Sql::V1::CloudSqlUsers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlUsersDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest'];

coerce 'SqlUsersDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest'->new($_) };

declare 'RepeatedSqlUsersDeleteRequest',
    as ArrayRef[SqlUsersDeleteRequest()];

coerce 'RepeatedSqlUsersDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlUsersDeleteRequest',
    as HashRef[SqlUsersDeleteRequest()];

declare 'SqlUsersGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest'];

coerce 'SqlUsersGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest'->new($_) };

declare 'RepeatedSqlUsersGetRequest',
    as ArrayRef[SqlUsersGetRequest()];

coerce 'RepeatedSqlUsersGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlUsersGetRequest',
    as HashRef[SqlUsersGetRequest()];

declare 'SqlUsersInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest'];

coerce 'SqlUsersInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest'->new($_) };

declare 'RepeatedSqlUsersInsertRequest',
    as ArrayRef[SqlUsersInsertRequest()];

coerce 'RepeatedSqlUsersInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlUsersInsertRequest',
    as HashRef[SqlUsersInsertRequest()];

declare 'SqlUsersListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest'];

coerce 'SqlUsersListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest'->new($_) };

declare 'RepeatedSqlUsersListRequest',
    as ArrayRef[SqlUsersListRequest()];

coerce 'RepeatedSqlUsersListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlUsersListRequest',
    as HashRef[SqlUsersListRequest()];

declare 'SqlUsersUpdateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest'];

coerce 'SqlUsersUpdateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest'->new($_) };

declare 'RepeatedSqlUsersUpdateRequest',
    as ArrayRef[SqlUsersUpdateRequest()];

coerce 'RepeatedSqlUsersUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlUsersUpdateRequest',
    as HashRef[SqlUsersUpdateRequest()];

declare 'UserPasswordValidationPolicy',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy'];

coerce 'UserPasswordValidationPolicy',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy'->new($_) };

declare 'RepeatedUserPasswordValidationPolicy',
    as ArrayRef[UserPasswordValidationPolicy()];

coerce 'RepeatedUserPasswordValidationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy'->new($_) } @$_ ] };

declare 'MapStringUserPasswordValidationPolicy',
    as HashRef[UserPasswordValidationPolicy()];

declare 'PasswordStatus',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus'];

coerce 'PasswordStatus',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus'->new($_) };

declare 'RepeatedPasswordStatus',
    as ArrayRef[PasswordStatus()];

coerce 'RepeatedPasswordStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus'->new($_) } @$_ ] };

declare 'MapStringPasswordStatus',
    as HashRef[PasswordStatus()];

declare 'User',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::User'];

coerce 'User',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'SqlUserType',
    as (Int | Str);

declare 'DualPasswordType',
    as (Int | Str);

declare 'IamStatus',
    as (Int | Str);

declare 'SqlServerUserDetails',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails'];

coerce 'SqlServerUserDetails',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails'->new($_) };

declare 'RepeatedSqlServerUserDetails',
    as ArrayRef[SqlServerUserDetails()];

coerce 'RepeatedSqlServerUserDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails'->new($_) } @$_ ] };

declare 'MapStringSqlServerUserDetails',
    as HashRef[SqlServerUserDetails()];

declare 'UsersListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse'];

coerce 'UsersListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse'->new($_) };

declare 'RepeatedUsersListResponse',
    as ArrayRef[UsersListResponse()];

coerce 'RepeatedUsersListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse'->new($_) } @$_ ] };

declare 'MapStringUsersListResponse',
    as HashRef[UsersListResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
