package Google::Devtools::Artifactregistry::Logging::V1::RequestLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RequestLog',
    as InstanceOf['Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog'];

coerce 'RequestLog',
    from HashRef, via { 'Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog'->new($_) };

declare 'RepeatedRequestLog',
    as ArrayRef[RequestLog()];

coerce 'RepeatedRequestLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog'->new($_) } @$_ ] };

declare 'MapStringRequestLog',
    as HashRef[RequestLog()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::Logging::V1::RequestLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
