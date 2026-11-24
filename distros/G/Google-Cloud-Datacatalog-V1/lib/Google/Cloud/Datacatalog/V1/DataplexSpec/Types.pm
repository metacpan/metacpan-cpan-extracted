package Google::Cloud::Datacatalog::V1::DataplexSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataplexSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec'];

coerce 'DataplexSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec'->new($_) };

declare 'RepeatedDataplexSpec',
    as ArrayRef[DataplexSpec()];

coerce 'RepeatedDataplexSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec'->new($_) } @$_ ] };

declare 'MapStringDataplexSpec',
    as HashRef[DataplexSpec()];

declare 'DataplexFilesetSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexFilesetSpec'];

coerce 'DataplexFilesetSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexFilesetSpec'->new($_) };

declare 'RepeatedDataplexFilesetSpec',
    as ArrayRef[DataplexFilesetSpec()];

coerce 'RepeatedDataplexFilesetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexFilesetSpec'->new($_) } @$_ ] };

declare 'MapStringDataplexFilesetSpec',
    as HashRef[DataplexFilesetSpec()];

declare 'DataplexTableSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexTableSpec'];

coerce 'DataplexTableSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexTableSpec'->new($_) };

declare 'RepeatedDataplexTableSpec',
    as ArrayRef[DataplexTableSpec()];

coerce 'RepeatedDataplexTableSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexTableSpec'->new($_) } @$_ ] };

declare 'MapStringDataplexTableSpec',
    as HashRef[DataplexTableSpec()];

declare 'DataplexExternalTable',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexExternalTable'];

coerce 'DataplexExternalTable',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexExternalTable'->new($_) };

declare 'RepeatedDataplexExternalTable',
    as ArrayRef[DataplexExternalTable()];

coerce 'RepeatedDataplexExternalTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexExternalTable'->new($_) } @$_ ] };

declare 'MapStringDataplexExternalTable',
    as HashRef[DataplexExternalTable()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::DataplexSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
