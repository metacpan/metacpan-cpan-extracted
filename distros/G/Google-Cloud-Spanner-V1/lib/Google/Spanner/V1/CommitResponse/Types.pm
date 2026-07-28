package Google::Spanner::V1::CommitResponse::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CommitResponse',
    as InstanceOf['Google::Spanner::V1::CommitResponse::CommitResponse'];

coerce 'CommitResponse',
    from HashRef, via { 'Google::Spanner::V1::CommitResponse::CommitResponse'->new($_) };

declare 'RepeatedCommitResponse',
    as ArrayRef[CommitResponse()];

coerce 'RepeatedCommitResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::CommitResponse::CommitResponse'->new($_) } @$_ ] };

declare 'MapStringCommitResponse',
    as HashRef[CommitResponse()];

declare 'CommitStats',
    as InstanceOf['Google::Spanner::V1::CommitResponse::CommitResponse::CommitStats'];

coerce 'CommitStats',
    from HashRef, via { 'Google::Spanner::V1::CommitResponse::CommitResponse::CommitStats'->new($_) };

declare 'RepeatedCommitStats',
    as ArrayRef[CommitStats()];

coerce 'RepeatedCommitStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::CommitResponse::CommitResponse::CommitStats'->new($_) } @$_ ] };

declare 'MapStringCommitStats',
    as HashRef[CommitStats()];

1;

__END__

=head1 NAME

Google::Spanner::V1::CommitResponse::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
