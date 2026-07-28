package Google::Cloud::Sql::V1::CloudSqlFlags::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlFlagType',
    as (Int | Str);

declare 'SqlFlagScope',
    as (Int | Str);

declare 'SqlFlagsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest'];

coerce 'SqlFlagsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest'->new($_) };

declare 'RepeatedSqlFlagsListRequest',
    as ArrayRef[SqlFlagsListRequest()];

coerce 'RepeatedSqlFlagsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlFlagsListRequest',
    as HashRef[SqlFlagsListRequest()];

declare 'FlagsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse'];

coerce 'FlagsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse'->new($_) };

declare 'RepeatedFlagsListResponse',
    as ArrayRef[FlagsListResponse()];

coerce 'RepeatedFlagsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse'->new($_) } @$_ ] };

declare 'MapStringFlagsListResponse',
    as HashRef[FlagsListResponse()];

declare 'Flag',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlFlags::Flag'];

coerce 'Flag',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlFlags::Flag'->new($_) };

declare 'RepeatedFlag',
    as ArrayRef[Flag()];

coerce 'RepeatedFlag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlFlags::Flag'->new($_) } @$_ ] };

declare 'MapStringFlag',
    as HashRef[Flag()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlFlags::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
