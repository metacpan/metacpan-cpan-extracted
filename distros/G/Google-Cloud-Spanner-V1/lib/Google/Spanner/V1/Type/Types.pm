package Google::Spanner::V1::Type::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TypeCode',
    as (Int | Str);

declare 'TypeAnnotationCode',
    as (Int | Str);

declare 'Type',
    as InstanceOf['Google::Spanner::V1::Type::Type'];

coerce 'Type',
    from HashRef, via { 'Google::Spanner::V1::Type::Type'->new($_) };

declare 'RepeatedType',
    as ArrayRef[Type()];

coerce 'RepeatedType',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Type::Type'->new($_) } @$_ ] };

declare 'MapStringType',
    as HashRef[Type()];

declare 'StructType',
    as InstanceOf['Google::Spanner::V1::Type::StructType'];

coerce 'StructType',
    from HashRef, via { 'Google::Spanner::V1::Type::StructType'->new($_) };

declare 'RepeatedStructType',
    as ArrayRef[StructType()];

coerce 'RepeatedStructType',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Type::StructType'->new($_) } @$_ ] };

declare 'MapStringStructType',
    as HashRef[StructType()];

declare 'Field',
    as InstanceOf['Google::Spanner::V1::Type::StructType::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Spanner::V1::Type::StructType::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Type::StructType::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

1;

__END__

=head1 NAME

Google::Spanner::V1::Type::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
