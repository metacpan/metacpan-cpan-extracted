package Google::Cloud::Bigquery::Storage::V1::Stream::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFormat',
    as (Int | Str);

declare 'WriteStreamView',
    as (Int | Str);

declare 'ReadSession',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession'];

coerce 'ReadSession',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession'->new($_) };

declare 'RepeatedReadSession',
    as ArrayRef[ReadSession()];

coerce 'RepeatedReadSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession'->new($_) } @$_ ] };

declare 'MapStringReadSession',
    as HashRef[ReadSession()];

declare 'TableModifiers',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession::TableModifiers'];

coerce 'TableModifiers',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession::TableModifiers'->new($_) };

declare 'RepeatedTableModifiers',
    as ArrayRef[TableModifiers()];

coerce 'RepeatedTableModifiers',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession::TableModifiers'->new($_) } @$_ ] };

declare 'MapStringTableModifiers',
    as HashRef[TableModifiers()];

declare 'TableReadOptions',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession::TableReadOptions'];

coerce 'TableReadOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession::TableReadOptions'->new($_) };

declare 'RepeatedTableReadOptions',
    as ArrayRef[TableReadOptions()];

coerce 'RepeatedTableReadOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession::TableReadOptions'->new($_) } @$_ ] };

declare 'MapStringTableReadOptions',
    as HashRef[TableReadOptions()];

declare 'ResponseCompressionCodec',
    as (Int | Str);

declare 'ReadStream',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Stream::ReadStream'];

coerce 'ReadStream',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadStream'->new($_) };

declare 'RepeatedReadStream',
    as ArrayRef[ReadStream()];

coerce 'RepeatedReadStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadStream'->new($_) } @$_ ] };

declare 'MapStringReadStream',
    as HashRef[ReadStream()];

declare 'WriteStream',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Stream::WriteStream'];

coerce 'WriteStream',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Stream::WriteStream'->new($_) };

declare 'RepeatedWriteStream',
    as ArrayRef[WriteStream()];

coerce 'RepeatedWriteStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Stream::WriteStream'->new($_) } @$_ ] };

declare 'MapStringWriteStream',
    as HashRef[WriteStream()];

declare 'Type',
    as (Int | Str);

declare 'WriteMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Stream::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
