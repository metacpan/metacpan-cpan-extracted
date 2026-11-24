package Google::Cloud::Metastore::Logging::V1::LogStreams::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RequestsLogEntry',
    as InstanceOf['Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry'];

coerce 'RequestsLogEntry',
    from HashRef, via { 'Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry'->new($_) };

declare 'RepeatedRequestsLogEntry',
    as ArrayRef[RequestsLogEntry()];

coerce 'RepeatedRequestsLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry'->new($_) } @$_ ] };

declare 'MapStringRequestsLogEntry',
    as HashRef[RequestsLogEntry()];

declare 'SystemActivityLogEntry',
    as InstanceOf['Google::Cloud::Metastore::Logging::V1::LogStreams::SystemActivityLogEntry'];

coerce 'SystemActivityLogEntry',
    from HashRef, via { 'Google::Cloud::Metastore::Logging::V1::LogStreams::SystemActivityLogEntry'->new($_) };

declare 'RepeatedSystemActivityLogEntry',
    as ArrayRef[SystemActivityLogEntry()];

coerce 'RepeatedSystemActivityLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::Logging::V1::LogStreams::SystemActivityLogEntry'->new($_) } @$_ ] };

declare 'MapStringSystemActivityLogEntry',
    as HashRef[SystemActivityLogEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Metastore::Logging::V1::LogStreams::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
