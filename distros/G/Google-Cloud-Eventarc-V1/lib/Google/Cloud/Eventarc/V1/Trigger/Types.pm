package Google::Cloud::Eventarc::V1::Trigger::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Trigger',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Trigger'];

coerce 'Trigger',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Trigger'->new($_) };

declare 'RepeatedTrigger',
    as ArrayRef[Trigger()];

coerce 'RepeatedTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Trigger'->new($_) } @$_ ] };

declare 'MapStringTrigger',
    as HashRef[Trigger()];

declare 'RetryPolicy',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Trigger::RetryPolicy'];

coerce 'RetryPolicy',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Trigger::RetryPolicy'->new($_) };

declare 'RepeatedRetryPolicy',
    as ArrayRef[RetryPolicy()];

coerce 'RepeatedRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Trigger::RetryPolicy'->new($_) } @$_ ] };

declare 'MapStringRetryPolicy',
    as HashRef[RetryPolicy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Trigger::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Trigger::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Trigger::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ConditionsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Trigger::ConditionsEntry'];

coerce 'ConditionsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Trigger::ConditionsEntry'->new($_) };

declare 'RepeatedConditionsEntry',
    as ArrayRef[ConditionsEntry()];

coerce 'RepeatedConditionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Trigger::ConditionsEntry'->new($_) } @$_ ] };

declare 'MapStringConditionsEntry',
    as HashRef[ConditionsEntry()];

declare 'EventFilter',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::EventFilter'];

coerce 'EventFilter',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::EventFilter'->new($_) };

declare 'RepeatedEventFilter',
    as ArrayRef[EventFilter()];

coerce 'RepeatedEventFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::EventFilter'->new($_) } @$_ ] };

declare 'MapStringEventFilter',
    as HashRef[EventFilter()];

declare 'StateCondition',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::StateCondition'];

coerce 'StateCondition',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::StateCondition'->new($_) };

declare 'RepeatedStateCondition',
    as ArrayRef[StateCondition()];

coerce 'RepeatedStateCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::StateCondition'->new($_) } @$_ ] };

declare 'MapStringStateCondition',
    as HashRef[StateCondition()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'Transport',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Transport'];

coerce 'Transport',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Transport'->new($_) };

declare 'RepeatedTransport',
    as ArrayRef[Transport()];

coerce 'RepeatedTransport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Transport'->new($_) } @$_ ] };

declare 'MapStringTransport',
    as HashRef[Transport()];

declare 'CloudRun',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::CloudRun'];

coerce 'CloudRun',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::CloudRun'->new($_) };

declare 'RepeatedCloudRun',
    as ArrayRef[CloudRun()];

coerce 'RepeatedCloudRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::CloudRun'->new($_) } @$_ ] };

declare 'MapStringCloudRun',
    as HashRef[CloudRun()];

declare 'GKE',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::GKE'];

coerce 'GKE',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::GKE'->new($_) };

declare 'RepeatedGKE',
    as ArrayRef[GKE()];

coerce 'RepeatedGKE',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::GKE'->new($_) } @$_ ] };

declare 'MapStringGKE',
    as HashRef[GKE()];

declare 'Pubsub',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::Pubsub'];

coerce 'Pubsub',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::Pubsub'->new($_) };

declare 'RepeatedPubsub',
    as ArrayRef[Pubsub()];

coerce 'RepeatedPubsub',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::Pubsub'->new($_) } @$_ ] };

declare 'MapStringPubsub',
    as HashRef[Pubsub()];

declare 'HttpEndpoint',
    as InstanceOf['Google::Cloud::Eventarc::V1::Trigger::HttpEndpoint'];

coerce 'HttpEndpoint',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Trigger::HttpEndpoint'->new($_) };

declare 'RepeatedHttpEndpoint',
    as ArrayRef[HttpEndpoint()];

coerce 'RepeatedHttpEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Trigger::HttpEndpoint'->new($_) } @$_ ] };

declare 'MapStringHttpEndpoint',
    as HashRef[HttpEndpoint()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::Trigger::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
