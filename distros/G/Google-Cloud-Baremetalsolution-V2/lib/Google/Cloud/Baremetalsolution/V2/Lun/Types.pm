package Google::Cloud::Baremetalsolution::V2::Lun::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Lun',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Lun::Lun'];

coerce 'Lun',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Lun::Lun'->new($_) };

declare 'RepeatedLun',
    as ArrayRef[Lun()];

coerce 'RepeatedLun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Lun::Lun'->new($_) } @$_ ] };

declare 'MapStringLun',
    as HashRef[Lun()];

declare 'State',
    as (Int | Str);

declare 'MultiprotocolType',
    as (Int | Str);

declare 'StorageType',
    as (Int | Str);

declare 'GetLunRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Lun::GetLunRequest'];

coerce 'GetLunRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Lun::GetLunRequest'->new($_) };

declare 'RepeatedGetLunRequest',
    as ArrayRef[GetLunRequest()];

coerce 'RepeatedGetLunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Lun::GetLunRequest'->new($_) } @$_ ] };

declare 'MapStringGetLunRequest',
    as HashRef[GetLunRequest()];

declare 'ListLunsRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Lun::ListLunsRequest'];

coerce 'ListLunsRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Lun::ListLunsRequest'->new($_) };

declare 'RepeatedListLunsRequest',
    as ArrayRef[ListLunsRequest()];

coerce 'RepeatedListLunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Lun::ListLunsRequest'->new($_) } @$_ ] };

declare 'MapStringListLunsRequest',
    as HashRef[ListLunsRequest()];

declare 'ListLunsResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Lun::ListLunsResponse'];

coerce 'ListLunsResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Lun::ListLunsResponse'->new($_) };

declare 'RepeatedListLunsResponse',
    as ArrayRef[ListLunsResponse()];

coerce 'RepeatedListLunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Lun::ListLunsResponse'->new($_) } @$_ ] };

declare 'MapStringListLunsResponse',
    as HashRef[ListLunsResponse()];

declare 'EvictLunRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Lun::EvictLunRequest'];

coerce 'EvictLunRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Lun::EvictLunRequest'->new($_) };

declare 'RepeatedEvictLunRequest',
    as ArrayRef[EvictLunRequest()];

coerce 'RepeatedEvictLunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Lun::EvictLunRequest'->new($_) } @$_ ] };

declare 'MapStringEvictLunRequest',
    as HashRef[EvictLunRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Lun::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
