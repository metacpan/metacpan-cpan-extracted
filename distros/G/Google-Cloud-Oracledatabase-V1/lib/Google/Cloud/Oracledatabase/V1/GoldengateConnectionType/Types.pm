package Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateConnectionType',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType'];

coerce 'GoldengateConnectionType',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType'->new($_) };

declare 'RepeatedGoldengateConnectionType',
    as ArrayRef[GoldengateConnectionType()];

coerce 'RepeatedGoldengateConnectionType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType'->new($_) } @$_ ] };

declare 'MapStringGoldengateConnectionType',
    as HashRef[GoldengateConnectionType()];

declare 'ConnectionType',
    as (Int | Str);

declare 'ListGoldengateConnectionTypesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesRequest'];

coerce 'ListGoldengateConnectionTypesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesRequest'->new($_) };

declare 'RepeatedListGoldengateConnectionTypesRequest',
    as ArrayRef[ListGoldengateConnectionTypesRequest()];

coerce 'RepeatedListGoldengateConnectionTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateConnectionTypesRequest',
    as HashRef[ListGoldengateConnectionTypesRequest()];

declare 'ListGoldengateConnectionTypesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesResponse'];

coerce 'ListGoldengateConnectionTypesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesResponse'->new($_) };

declare 'RepeatedListGoldengateConnectionTypesResponse',
    as ArrayRef[ListGoldengateConnectionTypesResponse()];

coerce 'RepeatedListGoldengateConnectionTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateConnectionTypesResponse',
    as HashRef[ListGoldengateConnectionTypesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
