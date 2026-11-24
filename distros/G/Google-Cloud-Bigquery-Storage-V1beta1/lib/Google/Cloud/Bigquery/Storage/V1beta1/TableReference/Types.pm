package Google::Cloud::Bigquery::Storage::V1beta1::TableReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableReference',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference'];

coerce 'TableReference',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference'->new($_) };

declare 'RepeatedTableReference',
    as ArrayRef[TableReference()];

coerce 'RepeatedTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference'->new($_) } @$_ ] };

declare 'MapStringTableReference',
    as HashRef[TableReference()];

declare 'TableModifiers',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableModifiers'];

coerce 'TableModifiers',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableModifiers'->new($_) };

declare 'RepeatedTableModifiers',
    as ArrayRef[TableModifiers()];

coerce 'RepeatedTableModifiers',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableModifiers'->new($_) } @$_ ] };

declare 'MapStringTableModifiers',
    as HashRef[TableModifiers()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::TableReference::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
