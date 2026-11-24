package Google::Cloud::Notebooks::V2::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'State',
    as (Int | Str);

declare 'HealthState',
    as (Int | Str);

declare 'UpgradeHistoryEntry',
    as InstanceOf['Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry'];

coerce 'UpgradeHistoryEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry'->new($_) };

declare 'RepeatedUpgradeHistoryEntry',
    as ArrayRef[UpgradeHistoryEntry()];

coerce 'RepeatedUpgradeHistoryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry'->new($_) } @$_ ] };

declare 'MapStringUpgradeHistoryEntry',
    as HashRef[UpgradeHistoryEntry()];

declare 'State',
    as (Int | Str);

declare 'Action',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Notebooks::V2::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'HealthInfoEntry',
    as InstanceOf['Google::Cloud::Notebooks::V2::Instance::Instance::HealthInfoEntry'];

coerce 'HealthInfoEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Instance::Instance::HealthInfoEntry'->new($_) };

declare 'RepeatedHealthInfoEntry',
    as ArrayRef[HealthInfoEntry()];

coerce 'RepeatedHealthInfoEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Instance::Instance::HealthInfoEntry'->new($_) } @$_ ] };

declare 'MapStringHealthInfoEntry',
    as HashRef[HealthInfoEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V2::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V2::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
