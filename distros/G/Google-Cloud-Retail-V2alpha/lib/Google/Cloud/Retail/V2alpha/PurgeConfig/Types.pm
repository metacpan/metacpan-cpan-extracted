package Google::Cloud::Retail::V2alpha::PurgeConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PurgeMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata'];

coerce 'PurgeMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata'->new($_) };

declare 'RepeatedPurgeMetadata',
    as ArrayRef[PurgeMetadata()];

coerce 'RepeatedPurgeMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata'->new($_) } @$_ ] };

declare 'MapStringPurgeMetadata',
    as HashRef[PurgeMetadata()];

declare 'PurgeProductsMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsMetadata'];

coerce 'PurgeProductsMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsMetadata'->new($_) };

declare 'RepeatedPurgeProductsMetadata',
    as ArrayRef[PurgeProductsMetadata()];

coerce 'RepeatedPurgeProductsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsMetadata'->new($_) } @$_ ] };

declare 'MapStringPurgeProductsMetadata',
    as HashRef[PurgeProductsMetadata()];

declare 'PurgeProductsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsRequest'];

coerce 'PurgeProductsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsRequest'->new($_) };

declare 'RepeatedPurgeProductsRequest',
    as ArrayRef[PurgeProductsRequest()];

coerce 'RepeatedPurgeProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeProductsRequest',
    as HashRef[PurgeProductsRequest()];

declare 'PurgeProductsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsResponse'];

coerce 'PurgeProductsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsResponse'->new($_) };

declare 'RepeatedPurgeProductsResponse',
    as ArrayRef[PurgeProductsResponse()];

coerce 'RepeatedPurgeProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsResponse'->new($_) } @$_ ] };

declare 'MapStringPurgeProductsResponse',
    as HashRef[PurgeProductsResponse()];

declare 'PurgeUserEventsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsRequest'];

coerce 'PurgeUserEventsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsRequest'->new($_) };

declare 'RepeatedPurgeUserEventsRequest',
    as ArrayRef[PurgeUserEventsRequest()];

coerce 'RepeatedPurgeUserEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeUserEventsRequest',
    as HashRef[PurgeUserEventsRequest()];

declare 'PurgeUserEventsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsResponse'];

coerce 'PurgeUserEventsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsResponse'->new($_) };

declare 'RepeatedPurgeUserEventsResponse',
    as ArrayRef[PurgeUserEventsResponse()];

coerce 'RepeatedPurgeUserEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsResponse'->new($_) } @$_ ] };

declare 'MapStringPurgeUserEventsResponse',
    as HashRef[PurgeUserEventsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::PurgeConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
