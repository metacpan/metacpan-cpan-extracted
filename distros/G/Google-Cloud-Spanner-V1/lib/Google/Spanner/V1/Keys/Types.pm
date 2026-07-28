package Google::Spanner::V1::Keys::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KeyRange',
    as InstanceOf['Google::Spanner::V1::Keys::KeyRange'];

coerce 'KeyRange',
    from HashRef, via { 'Google::Spanner::V1::Keys::KeyRange'->new($_) };

declare 'RepeatedKeyRange',
    as ArrayRef[KeyRange()];

coerce 'RepeatedKeyRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Keys::KeyRange'->new($_) } @$_ ] };

declare 'MapStringKeyRange',
    as HashRef[KeyRange()];

declare 'KeySet',
    as InstanceOf['Google::Spanner::V1::Keys::KeySet'];

coerce 'KeySet',
    from HashRef, via { 'Google::Spanner::V1::Keys::KeySet'->new($_) };

declare 'RepeatedKeySet',
    as ArrayRef[KeySet()];

coerce 'RepeatedKeySet',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Keys::KeySet'->new($_) } @$_ ] };

declare 'MapStringKeySet',
    as HashRef[KeySet()];

1;

__END__

=head1 NAME

Google::Spanner::V1::Keys::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
