package Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MessageBusActivity',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity'];

coerce 'MessageBusActivity',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity'->new($_) };

declare 'RepeatedMessageBusActivity',
    as ArrayRef[MessageBusActivity()];

coerce 'RepeatedMessageBusActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity'->new($_) } @$_ ] };

declare 'MapStringMessageBusActivity',
    as HashRef[MessageBusActivity()];

declare 'Received',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::Received'];

coerce 'Received',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::Received'->new($_) };

declare 'RepeatedReceived',
    as ArrayRef[Received()];

coerce 'RepeatedReceived',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::Received'->new($_) } @$_ ] };

declare 'MapStringReceived',
    as HashRef[Received()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
