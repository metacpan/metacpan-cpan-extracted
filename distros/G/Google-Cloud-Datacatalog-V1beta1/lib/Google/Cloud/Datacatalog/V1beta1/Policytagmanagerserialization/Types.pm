package Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SerializedTaxonomy',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy'];

coerce 'SerializedTaxonomy',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy'->new($_) };

declare 'RepeatedSerializedTaxonomy',
    as ArrayRef[SerializedTaxonomy()];

coerce 'RepeatedSerializedTaxonomy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy'->new($_) } @$_ ] };

declare 'MapStringSerializedTaxonomy',
    as HashRef[SerializedTaxonomy()];

declare 'SerializedPolicyTag',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag'];

coerce 'SerializedPolicyTag',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag'->new($_) };

declare 'RepeatedSerializedPolicyTag',
    as ArrayRef[SerializedPolicyTag()];

coerce 'RepeatedSerializedPolicyTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag'->new($_) } @$_ ] };

declare 'MapStringSerializedPolicyTag',
    as HashRef[SerializedPolicyTag()];

declare 'ImportTaxonomiesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesRequest'];

coerce 'ImportTaxonomiesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesRequest'->new($_) };

declare 'RepeatedImportTaxonomiesRequest',
    as ArrayRef[ImportTaxonomiesRequest()];

coerce 'RepeatedImportTaxonomiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesRequest'->new($_) } @$_ ] };

declare 'MapStringImportTaxonomiesRequest',
    as HashRef[ImportTaxonomiesRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ImportTaxonomiesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesResponse'];

coerce 'ImportTaxonomiesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesResponse'->new($_) };

declare 'RepeatedImportTaxonomiesResponse',
    as ArrayRef[ImportTaxonomiesResponse()];

coerce 'RepeatedImportTaxonomiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesResponse'->new($_) } @$_ ] };

declare 'MapStringImportTaxonomiesResponse',
    as HashRef[ImportTaxonomiesResponse()];

declare 'ExportTaxonomiesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesRequest'];

coerce 'ExportTaxonomiesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesRequest'->new($_) };

declare 'RepeatedExportTaxonomiesRequest',
    as ArrayRef[ExportTaxonomiesRequest()];

coerce 'RepeatedExportTaxonomiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesRequest'->new($_) } @$_ ] };

declare 'MapStringExportTaxonomiesRequest',
    as HashRef[ExportTaxonomiesRequest()];

declare 'ExportTaxonomiesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesResponse'];

coerce 'ExportTaxonomiesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesResponse'->new($_) };

declare 'RepeatedExportTaxonomiesResponse',
    as ArrayRef[ExportTaxonomiesResponse()];

coerce 'RepeatedExportTaxonomiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesResponse'->new($_) } @$_ ] };

declare 'MapStringExportTaxonomiesResponse',
    as HashRef[ExportTaxonomiesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
