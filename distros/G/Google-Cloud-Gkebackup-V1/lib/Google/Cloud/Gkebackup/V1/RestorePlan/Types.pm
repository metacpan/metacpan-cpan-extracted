package Google::Cloud::Gkebackup::V1::RestorePlan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestorePlan',
    as InstanceOf['Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan'];

coerce 'RestorePlan',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan'->new($_) };

declare 'RepeatedRestorePlan',
    as ArrayRef[RestorePlan()];

coerce 'RepeatedRestorePlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan'->new($_) } @$_ ] };

declare 'MapStringRestorePlan',
    as HashRef[RestorePlan()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::RestorePlan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
