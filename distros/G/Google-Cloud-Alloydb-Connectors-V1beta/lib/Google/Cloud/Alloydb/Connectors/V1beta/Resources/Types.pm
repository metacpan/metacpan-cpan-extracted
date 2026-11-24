package Google::Cloud::Alloydb::Connectors::V1beta::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MetadataExchangeRequest',
    as InstanceOf['Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest'];

coerce 'MetadataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest'->new($_) };

declare 'RepeatedMetadataExchangeRequest',
    as ArrayRef[MetadataExchangeRequest()];

coerce 'RepeatedMetadataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringMetadataExchangeRequest',
    as HashRef[MetadataExchangeRequest()];

declare 'AuthType',
    as (Int | Str);

declare 'MetadataExchangeResponse',
    as InstanceOf['Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeResponse'];

coerce 'MetadataExchangeResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeResponse'->new($_) };

declare 'RepeatedMetadataExchangeResponse',
    as ArrayRef[MetadataExchangeResponse()];

coerce 'RepeatedMetadataExchangeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeResponse'->new($_) } @$_ ] };

declare 'MapStringMetadataExchangeResponse',
    as HashRef[MetadataExchangeResponse()];

declare 'ResponseCode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::Connectors::V1beta::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
