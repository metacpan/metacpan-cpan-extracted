package Google::Cloud::Run::V2::Condition::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Condition',
    as InstanceOf['Google::Cloud::Run::V2::Condition::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Cloud::Run::V2::Condition::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Condition::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'State',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'CommonReason',
    as (Int | Str);

declare 'RevisionReason',
    as (Int | Str);

declare 'ExecutionReason',
    as (Int | Str);

declare 'InstanceReason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Condition::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
