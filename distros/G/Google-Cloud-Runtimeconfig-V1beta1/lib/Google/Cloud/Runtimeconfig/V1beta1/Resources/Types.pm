package Google::Cloud::Runtimeconfig::V1beta1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VariableState',
    as (Int | Str);

declare 'RuntimeConfig',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig'];

coerce 'RuntimeConfig',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig'->new($_) };

declare 'RepeatedRuntimeConfig',
    as ArrayRef[RuntimeConfig()];

coerce 'RepeatedRuntimeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeConfig',
    as HashRef[RuntimeConfig()];

declare 'Variable',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable'];

coerce 'Variable',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable'->new($_) };

declare 'RepeatedVariable',
    as ArrayRef[Variable()];

coerce 'RepeatedVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable'->new($_) } @$_ ] };

declare 'MapStringVariable',
    as HashRef[Variable()];

declare 'EndCondition',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition'];

coerce 'EndCondition',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition'->new($_) };

declare 'RepeatedEndCondition',
    as ArrayRef[EndCondition()];

coerce 'RepeatedEndCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition'->new($_) } @$_ ] };

declare 'MapStringEndCondition',
    as HashRef[EndCondition()];

declare 'Cardinality',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition::Cardinality'];

coerce 'Cardinality',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition::Cardinality'->new($_) };

declare 'RepeatedCardinality',
    as ArrayRef[Cardinality()];

coerce 'RepeatedCardinality',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition::Cardinality'->new($_) } @$_ ] };

declare 'MapStringCardinality',
    as HashRef[Cardinality()];

declare 'Waiter',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter'];

coerce 'Waiter',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter'->new($_) };

declare 'RepeatedWaiter',
    as ArrayRef[Waiter()];

coerce 'RepeatedWaiter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter'->new($_) } @$_ ] };

declare 'MapStringWaiter',
    as HashRef[Waiter()];

1;

__END__

=head1 NAME

Google::Cloud::Runtimeconfig::V1beta1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
