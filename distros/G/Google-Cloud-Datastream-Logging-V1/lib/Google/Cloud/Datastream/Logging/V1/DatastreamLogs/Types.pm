package Google::Cloud::Datastream::Logging::V1::DatastreamLogs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StreamActivityLogEntry',
    as InstanceOf['Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry'];

coerce 'StreamActivityLogEntry',
    from HashRef, via { 'Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry'->new($_) };

declare 'RepeatedStreamActivityLogEntry',
    as ArrayRef[StreamActivityLogEntry()];

coerce 'RepeatedStreamActivityLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry'->new($_) } @$_ ] };

declare 'MapStringStreamActivityLogEntry',
    as HashRef[StreamActivityLogEntry()];

declare 'StreamStateChange',
    as InstanceOf['Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry::StreamStateChange'];

coerce 'StreamStateChange',
    from HashRef, via { 'Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry::StreamStateChange'->new($_) };

declare 'RepeatedStreamStateChange',
    as ArrayRef[StreamStateChange()];

coerce 'RepeatedStreamStateChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry::StreamStateChange'->new($_) } @$_ ] };

declare 'MapStringStreamStateChange',
    as HashRef[StreamStateChange()];

1;

__END__

=head1 NAME

Google::Cloud::Datastream::Logging::V1::DatastreamLogs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
