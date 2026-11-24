package Google::Devtools::Build::V1::BuildEvents::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConsoleOutputStream',
    as (Int | Str);

declare 'BuildEvent',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent'];

coerce 'BuildEvent',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent'->new($_) };

declare 'RepeatedBuildEvent',
    as ArrayRef[BuildEvent()];

coerce 'RepeatedBuildEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent'->new($_) } @$_ ] };

declare 'MapStringBuildEvent',
    as HashRef[BuildEvent()];

declare 'InvocationAttemptStarted',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptStarted'];

coerce 'InvocationAttemptStarted',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptStarted'->new($_) };

declare 'RepeatedInvocationAttemptStarted',
    as ArrayRef[InvocationAttemptStarted()];

coerce 'RepeatedInvocationAttemptStarted',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptStarted'->new($_) } @$_ ] };

declare 'MapStringInvocationAttemptStarted',
    as HashRef[InvocationAttemptStarted()];

declare 'InvocationAttemptFinished',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptFinished'];

coerce 'InvocationAttemptFinished',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptFinished'->new($_) };

declare 'RepeatedInvocationAttemptFinished',
    as ArrayRef[InvocationAttemptFinished()];

coerce 'RepeatedInvocationAttemptFinished',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptFinished'->new($_) } @$_ ] };

declare 'MapStringInvocationAttemptFinished',
    as HashRef[InvocationAttemptFinished()];

declare 'BuildEnqueued',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildEnqueued'];

coerce 'BuildEnqueued',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildEnqueued'->new($_) };

declare 'RepeatedBuildEnqueued',
    as ArrayRef[BuildEnqueued()];

coerce 'RepeatedBuildEnqueued',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildEnqueued'->new($_) } @$_ ] };

declare 'MapStringBuildEnqueued',
    as HashRef[BuildEnqueued()];

declare 'BuildFinished',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildFinished'];

coerce 'BuildFinished',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildFinished'->new($_) };

declare 'RepeatedBuildFinished',
    as ArrayRef[BuildFinished()];

coerce 'RepeatedBuildFinished',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildFinished'->new($_) } @$_ ] };

declare 'MapStringBuildFinished',
    as HashRef[BuildFinished()];

declare 'ConsoleOutput',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent::ConsoleOutput'];

coerce 'ConsoleOutput',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::ConsoleOutput'->new($_) };

declare 'RepeatedConsoleOutput',
    as ArrayRef[ConsoleOutput()];

coerce 'RepeatedConsoleOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::ConsoleOutput'->new($_) } @$_ ] };

declare 'MapStringConsoleOutput',
    as HashRef[ConsoleOutput()];

declare 'BuildComponentStreamFinished',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildComponentStreamFinished'];

coerce 'BuildComponentStreamFinished',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildComponentStreamFinished'->new($_) };

declare 'RepeatedBuildComponentStreamFinished',
    as ArrayRef[BuildComponentStreamFinished()];

coerce 'RepeatedBuildComponentStreamFinished',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildComponentStreamFinished'->new($_) } @$_ ] };

declare 'MapStringBuildComponentStreamFinished',
    as HashRef[BuildComponentStreamFinished()];

declare 'FinishType',
    as (Int | Str);

declare 'StreamId',
    as InstanceOf['Google::Devtools::Build::V1::BuildEvents::StreamId'];

coerce 'StreamId',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildEvents::StreamId'->new($_) };

declare 'RepeatedStreamId',
    as ArrayRef[StreamId()];

coerce 'RepeatedStreamId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildEvents::StreamId'->new($_) } @$_ ] };

declare 'MapStringStreamId',
    as HashRef[StreamId()];

declare 'BuildComponent',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Devtools::Build::V1::BuildEvents::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
