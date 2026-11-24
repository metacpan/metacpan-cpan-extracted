package Google::Cloud::Stream::Logging::V1::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationEventType',
    as (Int | Str);

declare 'SessionEventType',
    as (Int | Str);

declare 'OperationEventLog',
    as InstanceOf['Google::Cloud::Stream::Logging::V1::Logging::OperationEventLog'];

coerce 'OperationEventLog',
    from HashRef, via { 'Google::Cloud::Stream::Logging::V1::Logging::OperationEventLog'->new($_) };

declare 'RepeatedOperationEventLog',
    as ArrayRef[OperationEventLog()];

coerce 'RepeatedOperationEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Stream::Logging::V1::Logging::OperationEventLog'->new($_) } @$_ ] };

declare 'MapStringOperationEventLog',
    as HashRef[OperationEventLog()];

declare 'OperationArtifact',
    as InstanceOf['Google::Cloud::Stream::Logging::V1::Logging::OperationArtifact'];

coerce 'OperationArtifact',
    from HashRef, via { 'Google::Cloud::Stream::Logging::V1::Logging::OperationArtifact'->new($_) };

declare 'RepeatedOperationArtifact',
    as ArrayRef[OperationArtifact()];

coerce 'RepeatedOperationArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Stream::Logging::V1::Logging::OperationArtifact'->new($_) } @$_ ] };

declare 'MapStringOperationArtifact',
    as HashRef[OperationArtifact()];

declare 'SessionEventLog',
    as InstanceOf['Google::Cloud::Stream::Logging::V1::Logging::SessionEventLog'];

coerce 'SessionEventLog',
    from HashRef, via { 'Google::Cloud::Stream::Logging::V1::Logging::SessionEventLog'->new($_) };

declare 'RepeatedSessionEventLog',
    as ArrayRef[SessionEventLog()];

coerce 'RepeatedSessionEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Stream::Logging::V1::Logging::SessionEventLog'->new($_) } @$_ ] };

declare 'MapStringSessionEventLog',
    as HashRef[SessionEventLog()];

1;

__END__

=head1 NAME

Google::Cloud::Stream::Logging::V1::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
