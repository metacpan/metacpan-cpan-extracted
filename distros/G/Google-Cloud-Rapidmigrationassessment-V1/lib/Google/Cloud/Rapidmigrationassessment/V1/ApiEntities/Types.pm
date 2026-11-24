package Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GuestOsScan',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan'];

coerce 'GuestOsScan',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan'->new($_) };

declare 'RepeatedGuestOsScan',
    as ArrayRef[GuestOsScan()];

coerce 'RepeatedGuestOsScan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan'->new($_) } @$_ ] };

declare 'MapStringGuestOsScan',
    as HashRef[GuestOsScan()];

declare 'VSphereScan',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::VSphereScan'];

coerce 'VSphereScan',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::VSphereScan'->new($_) };

declare 'RepeatedVSphereScan',
    as ArrayRef[VSphereScan()];

coerce 'RepeatedVSphereScan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::VSphereScan'->new($_) } @$_ ] };

declare 'MapStringVSphereScan',
    as HashRef[VSphereScan()];

declare 'Collector',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector'];

coerce 'Collector',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector'->new($_) };

declare 'RepeatedCollector',
    as ArrayRef[Collector()];

coerce 'RepeatedCollector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector'->new($_) } @$_ ] };

declare 'MapStringCollector',
    as HashRef[Collector()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Annotation',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation'];

coerce 'Annotation',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation'->new($_) };

declare 'RepeatedAnnotation',
    as ArrayRef[Annotation()];

coerce 'RepeatedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation'->new($_) } @$_ ] };

declare 'MapStringAnnotation',
    as HashRef[Annotation()];

declare 'Type',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
