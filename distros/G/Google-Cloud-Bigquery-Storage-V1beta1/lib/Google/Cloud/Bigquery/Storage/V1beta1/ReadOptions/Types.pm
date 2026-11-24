package Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableReadOptions',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions'];

coerce 'TableReadOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions'->new($_) };

declare 'RepeatedTableReadOptions',
    as ArrayRef[TableReadOptions()];

coerce 'RepeatedTableReadOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions'->new($_) } @$_ ] };

declare 'MapStringTableReadOptions',
    as HashRef[TableReadOptions()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
