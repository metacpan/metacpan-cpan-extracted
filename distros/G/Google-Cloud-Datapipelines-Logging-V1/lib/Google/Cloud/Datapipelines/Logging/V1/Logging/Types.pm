package Google::Cloud::Datapipelines::Logging::V1::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RequestLogEntry',
    as InstanceOf['Google::Cloud::Datapipelines::Logging::V1::Logging::RequestLogEntry'];

coerce 'RequestLogEntry',
    from HashRef, via { 'Google::Cloud::Datapipelines::Logging::V1::Logging::RequestLogEntry'->new($_) };

declare 'RepeatedRequestLogEntry',
    as ArrayRef[RequestLogEntry()];

coerce 'RepeatedRequestLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datapipelines::Logging::V1::Logging::RequestLogEntry'->new($_) } @$_ ] };

declare 'MapStringRequestLogEntry',
    as HashRef[RequestLogEntry()];

declare 'RequestType',
    as (Int | Str);

declare 'ErrorCause',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Datapipelines::Logging::V1::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
