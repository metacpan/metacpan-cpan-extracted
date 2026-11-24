package Google::Cloud::Visionai::V1alpha1::StreamsResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Stream',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream'];

coerce 'Stream',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream'->new($_) };

declare 'RepeatedStream',
    as ArrayRef[Stream()];

coerce 'RepeatedStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream'->new($_) } @$_ ] };

declare 'MapStringStream',
    as HashRef[Stream()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Event',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'Clock',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Series',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Series'];

coerce 'Series',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Series'->new($_) };

declare 'RepeatedSeries',
    as ArrayRef[Series()];

coerce 'RepeatedSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Series'->new($_) } @$_ ] };

declare 'MapStringSeries',
    as HashRef[Series()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Channel',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel'];

coerce 'Channel',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel'->new($_) };

declare 'RepeatedChannel',
    as ArrayRef[Channel()];

coerce 'RepeatedChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel'->new($_) } @$_ ] };

declare 'MapStringChannel',
    as HashRef[Channel()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1alpha1::StreamsResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
