package Google::Cloud::Bigquery::V2::TableReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableReference::TableReference'];

coerce 'TableReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableReference::TableReference'->new($_) };

declare 'RepeatedTableReference',
    as ArrayRef[TableReference()];

coerce 'RepeatedTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableReference::TableReference'->new($_) } @$_ ] };

declare 'MapStringTableReference',
    as HashRef[TableReference()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::TableReference::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
