package Google::Cloud::Gkebackup::V1::RestoreChannel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreChannel',
    as InstanceOf['Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel'];

coerce 'RestoreChannel',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel'->new($_) };

declare 'RepeatedRestoreChannel',
    as ArrayRef[RestoreChannel()];

coerce 'RepeatedRestoreChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel'->new($_) } @$_ ] };

declare 'MapStringRestoreChannel',
    as HashRef[RestoreChannel()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::RestoreChannel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
