package Google::Cloud::Bigquery::V2::DataFormatOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFormatOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions'];

coerce 'DataFormatOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions'->new($_) };

declare 'RepeatedDataFormatOptions',
    as ArrayRef[DataFormatOptions()];

coerce 'RepeatedDataFormatOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions'->new($_) } @$_ ] };

declare 'MapStringDataFormatOptions',
    as HashRef[DataFormatOptions()];

declare 'TimestampOutputFormat',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::DataFormatOptions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
