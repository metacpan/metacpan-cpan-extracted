package Google::Security::Safebrowsing::V5::Safebrowsing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ThreatType',
    as (Int | Str);

declare 'LikelySafeType',
    as (Int | Str);

declare 'ThreatAttribute',
    as (Int | Str);

declare 'SearchHashesRequest',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::SearchHashesRequest'];

coerce 'SearchHashesRequest',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::SearchHashesRequest'->new($_) };

declare 'RepeatedSearchHashesRequest',
    as ArrayRef[SearchHashesRequest()];

coerce 'RepeatedSearchHashesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::SearchHashesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchHashesRequest',
    as HashRef[SearchHashesRequest()];

declare 'SearchHashesResponse',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::SearchHashesResponse'];

coerce 'SearchHashesResponse',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::SearchHashesResponse'->new($_) };

declare 'RepeatedSearchHashesResponse',
    as ArrayRef[SearchHashesResponse()];

coerce 'RepeatedSearchHashesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::SearchHashesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchHashesResponse',
    as HashRef[SearchHashesResponse()];

declare 'FullHash',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::FullHash'];

coerce 'FullHash',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::FullHash'->new($_) };

declare 'RepeatedFullHash',
    as ArrayRef[FullHash()];

coerce 'RepeatedFullHash',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::FullHash'->new($_) } @$_ ] };

declare 'MapStringFullHash',
    as HashRef[FullHash()];

declare 'FullHashDetail',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::FullHash::FullHashDetail'];

coerce 'FullHashDetail',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::FullHash::FullHashDetail'->new($_) };

declare 'RepeatedFullHashDetail',
    as ArrayRef[FullHashDetail()];

coerce 'RepeatedFullHashDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::FullHash::FullHashDetail'->new($_) } @$_ ] };

declare 'MapStringFullHashDetail',
    as HashRef[FullHashDetail()];

declare 'GetHashListRequest',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::GetHashListRequest'];

coerce 'GetHashListRequest',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::GetHashListRequest'->new($_) };

declare 'RepeatedGetHashListRequest',
    as ArrayRef[GetHashListRequest()];

coerce 'RepeatedGetHashListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::GetHashListRequest'->new($_) } @$_ ] };

declare 'MapStringGetHashListRequest',
    as HashRef[GetHashListRequest()];

declare 'SizeConstraints',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::SizeConstraints'];

coerce 'SizeConstraints',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::SizeConstraints'->new($_) };

declare 'RepeatedSizeConstraints',
    as ArrayRef[SizeConstraints()];

coerce 'RepeatedSizeConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::SizeConstraints'->new($_) } @$_ ] };

declare 'MapStringSizeConstraints',
    as HashRef[SizeConstraints()];

declare 'RiceDeltaEncoded32Bit',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded32Bit'];

coerce 'RiceDeltaEncoded32Bit',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded32Bit'->new($_) };

declare 'RepeatedRiceDeltaEncoded32Bit',
    as ArrayRef[RiceDeltaEncoded32Bit()];

coerce 'RepeatedRiceDeltaEncoded32Bit',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded32Bit'->new($_) } @$_ ] };

declare 'MapStringRiceDeltaEncoded32Bit',
    as HashRef[RiceDeltaEncoded32Bit()];

declare 'RiceDeltaEncoded64Bit',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded64Bit'];

coerce 'RiceDeltaEncoded64Bit',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded64Bit'->new($_) };

declare 'RepeatedRiceDeltaEncoded64Bit',
    as ArrayRef[RiceDeltaEncoded64Bit()];

coerce 'RepeatedRiceDeltaEncoded64Bit',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded64Bit'->new($_) } @$_ ] };

declare 'MapStringRiceDeltaEncoded64Bit',
    as HashRef[RiceDeltaEncoded64Bit()];

declare 'RiceDeltaEncoded128Bit',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded128Bit'];

coerce 'RiceDeltaEncoded128Bit',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded128Bit'->new($_) };

declare 'RepeatedRiceDeltaEncoded128Bit',
    as ArrayRef[RiceDeltaEncoded128Bit()];

coerce 'RepeatedRiceDeltaEncoded128Bit',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded128Bit'->new($_) } @$_ ] };

declare 'MapStringRiceDeltaEncoded128Bit',
    as HashRef[RiceDeltaEncoded128Bit()];

declare 'RiceDeltaEncoded256Bit',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded256Bit'];

coerce 'RiceDeltaEncoded256Bit',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded256Bit'->new($_) };

declare 'RepeatedRiceDeltaEncoded256Bit',
    as ArrayRef[RiceDeltaEncoded256Bit()];

coerce 'RepeatedRiceDeltaEncoded256Bit',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::RiceDeltaEncoded256Bit'->new($_) } @$_ ] };

declare 'MapStringRiceDeltaEncoded256Bit',
    as HashRef[RiceDeltaEncoded256Bit()];

declare 'HashListMetadata',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::HashListMetadata'];

coerce 'HashListMetadata',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::HashListMetadata'->new($_) };

declare 'RepeatedHashListMetadata',
    as ArrayRef[HashListMetadata()];

coerce 'RepeatedHashListMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::HashListMetadata'->new($_) } @$_ ] };

declare 'MapStringHashListMetadata',
    as HashRef[HashListMetadata()];

declare 'HashLength',
    as (Int | Str);

declare 'HashList',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::HashList'];

coerce 'HashList',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::HashList'->new($_) };

declare 'RepeatedHashList',
    as ArrayRef[HashList()];

coerce 'RepeatedHashList',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::HashList'->new($_) } @$_ ] };

declare 'MapStringHashList',
    as HashRef[HashList()];

declare 'BatchGetHashListsRequest',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::BatchGetHashListsRequest'];

coerce 'BatchGetHashListsRequest',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::BatchGetHashListsRequest'->new($_) };

declare 'RepeatedBatchGetHashListsRequest',
    as ArrayRef[BatchGetHashListsRequest()];

coerce 'RepeatedBatchGetHashListsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::BatchGetHashListsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetHashListsRequest',
    as HashRef[BatchGetHashListsRequest()];

declare 'BatchGetHashListsResponse',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::BatchGetHashListsResponse'];

coerce 'BatchGetHashListsResponse',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::BatchGetHashListsResponse'->new($_) };

declare 'RepeatedBatchGetHashListsResponse',
    as ArrayRef[BatchGetHashListsResponse()];

coerce 'RepeatedBatchGetHashListsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::BatchGetHashListsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetHashListsResponse',
    as HashRef[BatchGetHashListsResponse()];

declare 'ListHashListsRequest',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::ListHashListsRequest'];

coerce 'ListHashListsRequest',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::ListHashListsRequest'->new($_) };

declare 'RepeatedListHashListsRequest',
    as ArrayRef[ListHashListsRequest()];

coerce 'RepeatedListHashListsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::ListHashListsRequest'->new($_) } @$_ ] };

declare 'MapStringListHashListsRequest',
    as HashRef[ListHashListsRequest()];

declare 'ListHashListsResponse',
    as InstanceOf['Google::Security::Safebrowsing::V5::Safebrowsing::ListHashListsResponse'];

coerce 'ListHashListsResponse',
    from HashRef, via { 'Google::Security::Safebrowsing::V5::Safebrowsing::ListHashListsResponse'->new($_) };

declare 'RepeatedListHashListsResponse',
    as ArrayRef[ListHashListsResponse()];

coerce 'RepeatedListHashListsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Security::Safebrowsing::V5::Safebrowsing::ListHashListsResponse'->new($_) } @$_ ] };

declare 'MapStringListHashListsResponse',
    as HashRef[ListHashListsResponse()];

1;

__END__

=head1 NAME

Google::Security::Safebrowsing::V5::Safebrowsing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
