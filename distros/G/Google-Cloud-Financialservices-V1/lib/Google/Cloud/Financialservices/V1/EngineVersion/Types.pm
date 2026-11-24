package Google::Cloud::Financialservices::V1::EngineVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EngineVersion',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion'];

coerce 'EngineVersion',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion'->new($_) };

declare 'RepeatedEngineVersion',
    as ArrayRef[EngineVersion()];

coerce 'RepeatedEngineVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion'->new($_) } @$_ ] };

declare 'MapStringEngineVersion',
    as HashRef[EngineVersion()];

declare 'State',
    as (Int | Str);

declare 'ListEngineVersionsRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsRequest'];

coerce 'ListEngineVersionsRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsRequest'->new($_) };

declare 'RepeatedListEngineVersionsRequest',
    as ArrayRef[ListEngineVersionsRequest()];

coerce 'RepeatedListEngineVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListEngineVersionsRequest',
    as HashRef[ListEngineVersionsRequest()];

declare 'ListEngineVersionsResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsResponse'];

coerce 'ListEngineVersionsResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsResponse'->new($_) };

declare 'RepeatedListEngineVersionsResponse',
    as ArrayRef[ListEngineVersionsResponse()];

coerce 'RepeatedListEngineVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListEngineVersionsResponse',
    as HashRef[ListEngineVersionsResponse()];

declare 'GetEngineVersionRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineVersion::GetEngineVersionRequest'];

coerce 'GetEngineVersionRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineVersion::GetEngineVersionRequest'->new($_) };

declare 'RepeatedGetEngineVersionRequest',
    as ArrayRef[GetEngineVersionRequest()];

coerce 'RepeatedGetEngineVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineVersion::GetEngineVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetEngineVersionRequest',
    as HashRef[GetEngineVersionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::EngineVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
