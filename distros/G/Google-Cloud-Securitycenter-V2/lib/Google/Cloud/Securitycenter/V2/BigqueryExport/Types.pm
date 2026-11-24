package Google::Cloud::Securitycenter::V2::BigqueryExport::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigQueryExport',
    as InstanceOf['Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport'];

coerce 'BigQueryExport',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport'->new($_) };

declare 'RepeatedBigQueryExport',
    as ArrayRef[BigQueryExport()];

coerce 'RepeatedBigQueryExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport'->new($_) } @$_ ] };

declare 'MapStringBigQueryExport',
    as HashRef[BigQueryExport()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::BigqueryExport::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
