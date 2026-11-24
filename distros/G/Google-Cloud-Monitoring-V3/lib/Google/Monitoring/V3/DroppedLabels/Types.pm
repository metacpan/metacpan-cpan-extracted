package Google::Monitoring::V3::DroppedLabels::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DroppedLabels',
    as InstanceOf['Google::Monitoring::V3::DroppedLabels::DroppedLabels'];

coerce 'DroppedLabels',
    from HashRef, via { 'Google::Monitoring::V3::DroppedLabels::DroppedLabels'->new($_) };

declare 'RepeatedDroppedLabels',
    as ArrayRef[DroppedLabels()];

coerce 'RepeatedDroppedLabels',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::DroppedLabels::DroppedLabels'->new($_) } @$_ ] };

declare 'MapStringDroppedLabels',
    as HashRef[DroppedLabels()];

declare 'LabelEntry',
    as InstanceOf['Google::Monitoring::V3::DroppedLabels::DroppedLabels::LabelEntry'];

coerce 'LabelEntry',
    from HashRef, via { 'Google::Monitoring::V3::DroppedLabels::DroppedLabels::LabelEntry'->new($_) };

declare 'RepeatedLabelEntry',
    as ArrayRef[LabelEntry()];

coerce 'RepeatedLabelEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::DroppedLabels::DroppedLabels::LabelEntry'->new($_) } @$_ ] };

declare 'MapStringLabelEntry',
    as HashRef[LabelEntry()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::DroppedLabels::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
