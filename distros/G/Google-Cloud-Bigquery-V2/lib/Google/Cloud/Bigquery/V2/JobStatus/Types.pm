package Google::Cloud::Bigquery::V2::JobStatus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobStatus',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStatus::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStatus::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStatus::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::JobStatus::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
