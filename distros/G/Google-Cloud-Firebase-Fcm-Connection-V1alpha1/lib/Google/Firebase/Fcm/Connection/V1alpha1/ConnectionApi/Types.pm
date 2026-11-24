package Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpstreamRequest',
    as InstanceOf['Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest'];

coerce 'UpstreamRequest',
    from HashRef, via { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest'->new($_) };

declare 'RepeatedUpstreamRequest',
    as ArrayRef[UpstreamRequest()];

coerce 'RepeatedUpstreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest'->new($_) } @$_ ] };

declare 'MapStringUpstreamRequest',
    as HashRef[UpstreamRequest()];

declare 'DownstreamResponse',
    as InstanceOf['Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::DownstreamResponse'];

coerce 'DownstreamResponse',
    from HashRef, via { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::DownstreamResponse'->new($_) };

declare 'RepeatedDownstreamResponse',
    as ArrayRef[DownstreamResponse()];

coerce 'RepeatedDownstreamResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::DownstreamResponse'->new($_) } @$_ ] };

declare 'MapStringDownstreamResponse',
    as HashRef[DownstreamResponse()];

declare 'Ack',
    as InstanceOf['Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Ack'];

coerce 'Ack',
    from HashRef, via { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Ack'->new($_) };

declare 'RepeatedAck',
    as ArrayRef[Ack()];

coerce 'RepeatedAck',
    from ArrayRef[HashRef], via { [ map { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Ack'->new($_) } @$_ ] };

declare 'MapStringAck',
    as HashRef[Ack()];

declare 'Message',
    as InstanceOf['Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'DataEntry',
    as InstanceOf['Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message::DataEntry'];

coerce 'DataEntry',
    from HashRef, via { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message::DataEntry'->new($_) };

declare 'RepeatedDataEntry',
    as ArrayRef[DataEntry()];

coerce 'RepeatedDataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message::DataEntry'->new($_) } @$_ ] };

declare 'MapStringDataEntry',
    as HashRef[DataEntry()];

1;

__END__

=head1 NAME

Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
