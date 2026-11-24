package Google::Cloud::Websecurityscanner::V1::FindingTypeStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FindingTypeStats',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats'];

coerce 'FindingTypeStats',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats'->new($_) };

declare 'RepeatedFindingTypeStats',
    as ArrayRef[FindingTypeStats()];

coerce 'RepeatedFindingTypeStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats'->new($_) } @$_ ] };

declare 'MapStringFindingTypeStats',
    as HashRef[FindingTypeStats()];

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1::FindingTypeStats::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
