package Google::Appengine::Logging::V1::RequestLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogLine',
    as InstanceOf['Google::Appengine::Logging::V1::RequestLog::LogLine'];

coerce 'LogLine',
    from HashRef, via { 'Google::Appengine::Logging::V1::RequestLog::LogLine'->new($_) };

declare 'RepeatedLogLine',
    as ArrayRef[LogLine()];

coerce 'RepeatedLogLine',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::Logging::V1::RequestLog::LogLine'->new($_) } @$_ ] };

declare 'MapStringLogLine',
    as HashRef[LogLine()];

declare 'SourceLocation',
    as InstanceOf['Google::Appengine::Logging::V1::RequestLog::SourceLocation'];

coerce 'SourceLocation',
    from HashRef, via { 'Google::Appengine::Logging::V1::RequestLog::SourceLocation'->new($_) };

declare 'RepeatedSourceLocation',
    as ArrayRef[SourceLocation()];

coerce 'RepeatedSourceLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::Logging::V1::RequestLog::SourceLocation'->new($_) } @$_ ] };

declare 'MapStringSourceLocation',
    as HashRef[SourceLocation()];

declare 'SourceReference',
    as InstanceOf['Google::Appengine::Logging::V1::RequestLog::SourceReference'];

coerce 'SourceReference',
    from HashRef, via { 'Google::Appengine::Logging::V1::RequestLog::SourceReference'->new($_) };

declare 'RepeatedSourceReference',
    as ArrayRef[SourceReference()];

coerce 'RepeatedSourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::Logging::V1::RequestLog::SourceReference'->new($_) } @$_ ] };

declare 'MapStringSourceReference',
    as HashRef[SourceReference()];

declare 'RequestLog',
    as InstanceOf['Google::Appengine::Logging::V1::RequestLog::RequestLog'];

coerce 'RequestLog',
    from HashRef, via { 'Google::Appengine::Logging::V1::RequestLog::RequestLog'->new($_) };

declare 'RepeatedRequestLog',
    as ArrayRef[RequestLog()];

coerce 'RepeatedRequestLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::Logging::V1::RequestLog::RequestLog'->new($_) } @$_ ] };

declare 'MapStringRequestLog',
    as HashRef[RequestLog()];

1;

__END__

=head1 NAME

Google::Appengine::Logging::V1::RequestLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
