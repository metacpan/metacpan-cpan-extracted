package Google::Cloud::Eventarc::Publishing::V1::CloudEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudEvent',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent'];

coerce 'CloudEvent',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent'->new($_) };

declare 'RepeatedCloudEvent',
    as ArrayRef[CloudEvent()];

coerce 'RepeatedCloudEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent'->new($_) } @$_ ] };

declare 'MapStringCloudEvent',
    as HashRef[CloudEvent()];

declare 'CloudEventAttributeValue',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::CloudEventAttributeValue'];

coerce 'CloudEventAttributeValue',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::CloudEventAttributeValue'->new($_) };

declare 'RepeatedCloudEventAttributeValue',
    as ArrayRef[CloudEventAttributeValue()];

coerce 'RepeatedCloudEventAttributeValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::CloudEventAttributeValue'->new($_) } @$_ ] };

declare 'MapStringCloudEventAttributeValue',
    as HashRef[CloudEventAttributeValue()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::Publishing::V1::CloudEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
