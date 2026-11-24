package Google::Cloud::Optimization::V1::AsyncModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFormat',
    as (Int | Str);

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Optimization::V1::AsyncModel::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Optimization::V1::AsyncModel::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::AsyncModel::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Optimization::V1::AsyncModel::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Optimization::V1::AsyncModel::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::AsyncModel::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Optimization::V1::AsyncModel::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Optimization::V1::AsyncModel::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::AsyncModel::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Optimization::V1::AsyncModel::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Optimization::V1::AsyncModel::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::AsyncModel::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'AsyncModelMetadata',
    as InstanceOf['Google::Cloud::Optimization::V1::AsyncModel::AsyncModelMetadata'];

coerce 'AsyncModelMetadata',
    from HashRef, via { 'Google::Cloud::Optimization::V1::AsyncModel::AsyncModelMetadata'->new($_) };

declare 'RepeatedAsyncModelMetadata',
    as ArrayRef[AsyncModelMetadata()];

coerce 'RepeatedAsyncModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::AsyncModel::AsyncModelMetadata'->new($_) } @$_ ] };

declare 'MapStringAsyncModelMetadata',
    as HashRef[AsyncModelMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Optimization::V1::AsyncModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
