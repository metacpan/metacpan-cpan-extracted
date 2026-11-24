package Google::Monitoring::V3::MutationRecord::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MutationRecord',
    as InstanceOf['Google::Monitoring::V3::MutationRecord::MutationRecord'];

coerce 'MutationRecord',
    from HashRef, via { 'Google::Monitoring::V3::MutationRecord::MutationRecord'->new($_) };

declare 'RepeatedMutationRecord',
    as ArrayRef[MutationRecord()];

coerce 'RepeatedMutationRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MutationRecord::MutationRecord'->new($_) } @$_ ] };

declare 'MapStringMutationRecord',
    as HashRef[MutationRecord()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::MutationRecord::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
