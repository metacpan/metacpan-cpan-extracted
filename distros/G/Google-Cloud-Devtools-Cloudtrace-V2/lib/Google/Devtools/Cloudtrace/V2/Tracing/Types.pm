package Google::Devtools::Cloudtrace::V2::Tracing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BatchWriteSpansRequest',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest'];

coerce 'BatchWriteSpansRequest',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest'->new($_) };

declare 'RepeatedBatchWriteSpansRequest',
    as ArrayRef[BatchWriteSpansRequest()];

coerce 'RepeatedBatchWriteSpansRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest'->new($_) } @$_ ] };

declare 'MapStringBatchWriteSpansRequest',
    as HashRef[BatchWriteSpansRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudtrace::V2::Tracing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
