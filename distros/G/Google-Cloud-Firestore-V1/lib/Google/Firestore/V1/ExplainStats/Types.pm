package Google::Firestore::V1::ExplainStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExplainStats',
    as InstanceOf['Google::Firestore::V1::ExplainStats::ExplainStats'];

coerce 'ExplainStats',
    from HashRef, via { 'Google::Firestore::V1::ExplainStats::ExplainStats'->new($_) };

declare 'RepeatedExplainStats',
    as ArrayRef[ExplainStats()];

coerce 'RepeatedExplainStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::ExplainStats::ExplainStats'->new($_) } @$_ ] };

declare 'MapStringExplainStats',
    as HashRef[ExplainStats()];

1;

__END__

=head1 NAME

Google::Firestore::V1::ExplainStats::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
