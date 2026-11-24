package Google::Cloud::Eventarc::V1::MessageBus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MessageBus',
    as InstanceOf['Google::Cloud::Eventarc::V1::MessageBus::MessageBus'];

coerce 'MessageBus',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::MessageBus::MessageBus'->new($_) };

declare 'RepeatedMessageBus',
    as ArrayRef[MessageBus()];

coerce 'RepeatedMessageBus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::MessageBus::MessageBus'->new($_) } @$_ ] };

declare 'MapStringMessageBus',
    as HashRef[MessageBus()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::MessageBus::MessageBus::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::MessageBus::MessageBus::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::MessageBus::MessageBus::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::MessageBus::MessageBus::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::MessageBus::MessageBus::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::MessageBus::MessageBus::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::MessageBus::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
