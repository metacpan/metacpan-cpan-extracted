package Google::Cloud::Dataplex::V1::DatascansCommon::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataScanCatalogPublishingStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::DatascansCommon::DataScanCatalogPublishingStatus'];

coerce 'DataScanCatalogPublishingStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DatascansCommon::DataScanCatalogPublishingStatus'->new($_) };

declare 'RepeatedDataScanCatalogPublishingStatus',
    as ArrayRef[DataScanCatalogPublishingStatus()];

coerce 'RepeatedDataScanCatalogPublishingStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DatascansCommon::DataScanCatalogPublishingStatus'->new($_) } @$_ ] };

declare 'MapStringDataScanCatalogPublishingStatus',
    as HashRef[DataScanCatalogPublishingStatus()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DatascansCommon::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
