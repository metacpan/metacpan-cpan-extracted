package Google::Cloud::Eventarc::V1::Enrollment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Enrollment',
    as InstanceOf['Google::Cloud::Eventarc::V1::Enrollment::Enrollment'];

coerce 'Enrollment',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Enrollment::Enrollment'->new($_) };

declare 'RepeatedEnrollment',
    as ArrayRef[Enrollment()];

coerce 'RepeatedEnrollment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Enrollment::Enrollment'->new($_) } @$_ ] };

declare 'MapStringEnrollment',
    as HashRef[Enrollment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Enrollment::Enrollment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Enrollment::Enrollment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Enrollment::Enrollment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Enrollment::Enrollment::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Enrollment::Enrollment::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Enrollment::Enrollment::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::Enrollment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
