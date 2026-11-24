package Google::Cloud::Eventarc::V1::ChannelConnection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChannelConnection',
    as InstanceOf['Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection'];

coerce 'ChannelConnection',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection'->new($_) };

declare 'RepeatedChannelConnection',
    as ArrayRef[ChannelConnection()];

coerce 'RepeatedChannelConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection'->new($_) } @$_ ] };

declare 'MapStringChannelConnection',
    as HashRef[ChannelConnection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::ChannelConnection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
