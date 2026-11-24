package Google::Cloud::Ces::V1beta::BigqueryExport::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigQueryExportSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings'];

coerce 'BigQueryExportSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings'->new($_) };

declare 'RepeatedBigQueryExportSettings',
    as ArrayRef[BigQueryExportSettings()];

coerce 'RepeatedBigQueryExportSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings'->new($_) } @$_ ] };

declare 'MapStringBigQueryExportSettings',
    as HashRef[BigQueryExportSettings()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::BigqueryExport::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
