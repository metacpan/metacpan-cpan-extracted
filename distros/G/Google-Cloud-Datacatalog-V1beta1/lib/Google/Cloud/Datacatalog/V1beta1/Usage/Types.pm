package Google::Cloud::Datacatalog::V1beta1::Usage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UsageStats',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats'];

coerce 'UsageStats',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats'->new($_) };

declare 'RepeatedUsageStats',
    as ArrayRef[UsageStats()];

coerce 'RepeatedUsageStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats'->new($_) } @$_ ] };

declare 'MapStringUsageStats',
    as HashRef[UsageStats()];

declare 'UsageSignal',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal'];

coerce 'UsageSignal',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal'->new($_) };

declare 'RepeatedUsageSignal',
    as ArrayRef[UsageSignal()];

coerce 'RepeatedUsageSignal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal'->new($_) } @$_ ] };

declare 'MapStringUsageSignal',
    as HashRef[UsageSignal()];

declare 'UsageWithinTimeRangeEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal::UsageWithinTimeRangeEntry'];

coerce 'UsageWithinTimeRangeEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal::UsageWithinTimeRangeEntry'->new($_) };

declare 'RepeatedUsageWithinTimeRangeEntry',
    as ArrayRef[UsageWithinTimeRangeEntry()];

coerce 'RepeatedUsageWithinTimeRangeEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal::UsageWithinTimeRangeEntry'->new($_) } @$_ ] };

declare 'MapStringUsageWithinTimeRangeEntry',
    as HashRef[UsageWithinTimeRangeEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Usage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
