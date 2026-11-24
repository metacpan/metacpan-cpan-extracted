package Google::Cloud::Pubsublite::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttributeValues',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::AttributeValues'];

coerce 'AttributeValues',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::AttributeValues'->new($_) };

declare 'RepeatedAttributeValues',
    as ArrayRef[AttributeValues()];

coerce 'RepeatedAttributeValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::AttributeValues'->new($_) } @$_ ] };

declare 'MapStringAttributeValues',
    as HashRef[AttributeValues()];

declare 'PubSubMessage',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::PubSubMessage'];

coerce 'PubSubMessage',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::PubSubMessage'->new($_) };

declare 'RepeatedPubSubMessage',
    as ArrayRef[PubSubMessage()];

coerce 'RepeatedPubSubMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::PubSubMessage'->new($_) } @$_ ] };

declare 'MapStringPubSubMessage',
    as HashRef[PubSubMessage()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::PubSubMessage::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::PubSubMessage::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::PubSubMessage::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Cursor',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Cursor'];

coerce 'Cursor',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Cursor'->new($_) };

declare 'RepeatedCursor',
    as ArrayRef[Cursor()];

coerce 'RepeatedCursor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Cursor'->new($_) } @$_ ] };

declare 'MapStringCursor',
    as HashRef[Cursor()];

declare 'SequencedMessage',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::SequencedMessage'];

coerce 'SequencedMessage',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::SequencedMessage'->new($_) };

declare 'RepeatedSequencedMessage',
    as ArrayRef[SequencedMessage()];

coerce 'RepeatedSequencedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::SequencedMessage'->new($_) } @$_ ] };

declare 'MapStringSequencedMessage',
    as HashRef[SequencedMessage()];

declare 'Reservation',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Reservation'];

coerce 'Reservation',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Reservation'->new($_) };

declare 'RepeatedReservation',
    as ArrayRef[Reservation()];

coerce 'RepeatedReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Reservation'->new($_) } @$_ ] };

declare 'MapStringReservation',
    as HashRef[Reservation()];

declare 'Topic',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Topic'];

coerce 'Topic',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Topic'->new($_) };

declare 'RepeatedTopic',
    as ArrayRef[Topic()];

coerce 'RepeatedTopic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Topic'->new($_) } @$_ ] };

declare 'MapStringTopic',
    as HashRef[Topic()];

declare 'PartitionConfig',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig'];

coerce 'PartitionConfig',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig'->new($_) };

declare 'RepeatedPartitionConfig',
    as ArrayRef[PartitionConfig()];

coerce 'RepeatedPartitionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig'->new($_) } @$_ ] };

declare 'MapStringPartitionConfig',
    as HashRef[PartitionConfig()];

declare 'Capacity',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig::Capacity'];

coerce 'Capacity',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig::Capacity'->new($_) };

declare 'RepeatedCapacity',
    as ArrayRef[Capacity()];

coerce 'RepeatedCapacity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig::Capacity'->new($_) } @$_ ] };

declare 'MapStringCapacity',
    as HashRef[Capacity()];

declare 'RetentionConfig',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Topic::RetentionConfig'];

coerce 'RetentionConfig',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Topic::RetentionConfig'->new($_) };

declare 'RepeatedRetentionConfig',
    as ArrayRef[RetentionConfig()];

coerce 'RepeatedRetentionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Topic::RetentionConfig'->new($_) } @$_ ] };

declare 'MapStringRetentionConfig',
    as HashRef[RetentionConfig()];

declare 'ReservationConfig',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Topic::ReservationConfig'];

coerce 'ReservationConfig',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Topic::ReservationConfig'->new($_) };

declare 'RepeatedReservationConfig',
    as ArrayRef[ReservationConfig()];

coerce 'RepeatedReservationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Topic::ReservationConfig'->new($_) } @$_ ] };

declare 'MapStringReservationConfig',
    as HashRef[ReservationConfig()];

declare 'Subscription',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Subscription'];

coerce 'Subscription',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Subscription'->new($_) };

declare 'RepeatedSubscription',
    as ArrayRef[Subscription()];

coerce 'RepeatedSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Subscription'->new($_) } @$_ ] };

declare 'MapStringSubscription',
    as HashRef[Subscription()];

declare 'DeliveryConfig',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::Subscription::DeliveryConfig'];

coerce 'DeliveryConfig',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::Subscription::DeliveryConfig'->new($_) };

declare 'RepeatedDeliveryConfig',
    as ArrayRef[DeliveryConfig()];

coerce 'RepeatedDeliveryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::Subscription::DeliveryConfig'->new($_) } @$_ ] };

declare 'MapStringDeliveryConfig',
    as HashRef[DeliveryConfig()];

declare 'DeliveryRequirement',
    as (Int | Str);

declare 'ExportConfig',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::ExportConfig'];

coerce 'ExportConfig',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::ExportConfig'->new($_) };

declare 'RepeatedExportConfig',
    as ArrayRef[ExportConfig()];

coerce 'RepeatedExportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::ExportConfig'->new($_) } @$_ ] };

declare 'MapStringExportConfig',
    as HashRef[ExportConfig()];

declare 'State',
    as (Int | Str);

declare 'PubSubConfig',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::ExportConfig::PubSubConfig'];

coerce 'PubSubConfig',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::ExportConfig::PubSubConfig'->new($_) };

declare 'RepeatedPubSubConfig',
    as ArrayRef[PubSubConfig()];

coerce 'RepeatedPubSubConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::ExportConfig::PubSubConfig'->new($_) } @$_ ] };

declare 'MapStringPubSubConfig',
    as HashRef[PubSubConfig()];

declare 'TimeTarget',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Common::TimeTarget'];

coerce 'TimeTarget',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Common::TimeTarget'->new($_) };

declare 'RepeatedTimeTarget',
    as ArrayRef[TimeTarget()];

coerce 'RepeatedTimeTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Common::TimeTarget'->new($_) } @$_ ] };

declare 'MapStringTimeTarget',
    as HashRef[TimeTarget()];

1;

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
