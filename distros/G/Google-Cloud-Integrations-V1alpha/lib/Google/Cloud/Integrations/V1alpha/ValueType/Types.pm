package Google::Cloud::Integrations::V1alpha::ValueType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValueType',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::ValueType::ValueType'];

coerce 'ValueType',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::ValueType::ValueType'->new($_) };

declare 'RepeatedValueType',
    as ArrayRef[ValueType()];

coerce 'RepeatedValueType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::ValueType::ValueType'->new($_) } @$_ ] };

declare 'MapStringValueType',
    as HashRef[ValueType()];

declare 'StringParameterArray',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::ValueType::StringParameterArray'];

coerce 'StringParameterArray',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::ValueType::StringParameterArray'->new($_) };

declare 'RepeatedStringParameterArray',
    as ArrayRef[StringParameterArray()];

coerce 'RepeatedStringParameterArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::ValueType::StringParameterArray'->new($_) } @$_ ] };

declare 'MapStringStringParameterArray',
    as HashRef[StringParameterArray()];

declare 'IntParameterArray',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::ValueType::IntParameterArray'];

coerce 'IntParameterArray',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::ValueType::IntParameterArray'->new($_) };

declare 'RepeatedIntParameterArray',
    as ArrayRef[IntParameterArray()];

coerce 'RepeatedIntParameterArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::ValueType::IntParameterArray'->new($_) } @$_ ] };

declare 'MapStringIntParameterArray',
    as HashRef[IntParameterArray()];

declare 'DoubleParameterArray',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::ValueType::DoubleParameterArray'];

coerce 'DoubleParameterArray',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::ValueType::DoubleParameterArray'->new($_) };

declare 'RepeatedDoubleParameterArray',
    as ArrayRef[DoubleParameterArray()];

coerce 'RepeatedDoubleParameterArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::ValueType::DoubleParameterArray'->new($_) } @$_ ] };

declare 'MapStringDoubleParameterArray',
    as HashRef[DoubleParameterArray()];

declare 'BooleanParameterArray',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::ValueType::BooleanParameterArray'];

coerce 'BooleanParameterArray',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::ValueType::BooleanParameterArray'->new($_) };

declare 'RepeatedBooleanParameterArray',
    as ArrayRef[BooleanParameterArray()];

coerce 'RepeatedBooleanParameterArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::ValueType::BooleanParameterArray'->new($_) } @$_ ] };

declare 'MapStringBooleanParameterArray',
    as HashRef[BooleanParameterArray()];

1;

__END__

=head1 NAME

Google::Cloud::Integrations::V1alpha::ValueType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
