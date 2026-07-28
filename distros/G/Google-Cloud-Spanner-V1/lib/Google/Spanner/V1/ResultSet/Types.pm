package Google::Spanner::V1::ResultSet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResultSet',
    as InstanceOf['Google::Spanner::V1::ResultSet::ResultSet'];

coerce 'ResultSet',
    from HashRef, via { 'Google::Spanner::V1::ResultSet::ResultSet'->new($_) };

declare 'RepeatedResultSet',
    as ArrayRef[ResultSet()];

coerce 'RepeatedResultSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ResultSet::ResultSet'->new($_) } @$_ ] };

declare 'MapStringResultSet',
    as HashRef[ResultSet()];

declare 'PartialResultSet',
    as InstanceOf['Google::Spanner::V1::ResultSet::PartialResultSet'];

coerce 'PartialResultSet',
    from HashRef, via { 'Google::Spanner::V1::ResultSet::PartialResultSet'->new($_) };

declare 'RepeatedPartialResultSet',
    as ArrayRef[PartialResultSet()];

coerce 'RepeatedPartialResultSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ResultSet::PartialResultSet'->new($_) } @$_ ] };

declare 'MapStringPartialResultSet',
    as HashRef[PartialResultSet()];

declare 'ResultSetMetadata',
    as InstanceOf['Google::Spanner::V1::ResultSet::ResultSetMetadata'];

coerce 'ResultSetMetadata',
    from HashRef, via { 'Google::Spanner::V1::ResultSet::ResultSetMetadata'->new($_) };

declare 'RepeatedResultSetMetadata',
    as ArrayRef[ResultSetMetadata()];

coerce 'RepeatedResultSetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ResultSet::ResultSetMetadata'->new($_) } @$_ ] };

declare 'MapStringResultSetMetadata',
    as HashRef[ResultSetMetadata()];

declare 'ResultSetStats',
    as InstanceOf['Google::Spanner::V1::ResultSet::ResultSetStats'];

coerce 'ResultSetStats',
    from HashRef, via { 'Google::Spanner::V1::ResultSet::ResultSetStats'->new($_) };

declare 'RepeatedResultSetStats',
    as ArrayRef[ResultSetStats()];

coerce 'RepeatedResultSetStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ResultSet::ResultSetStats'->new($_) } @$_ ] };

declare 'MapStringResultSetStats',
    as HashRef[ResultSetStats()];

1;

__END__

=head1 NAME

Google::Spanner::V1::ResultSet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
