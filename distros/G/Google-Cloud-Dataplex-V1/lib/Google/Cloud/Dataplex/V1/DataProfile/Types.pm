package Google::Cloud::Dataplex::V1::DataProfile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataProfileSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec'];

coerce 'DataProfileSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec'->new($_) };

declare 'RepeatedDataProfileSpec',
    as ArrayRef[DataProfileSpec()];

coerce 'RepeatedDataProfileSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec'->new($_) } @$_ ] };

declare 'MapStringDataProfileSpec',
    as HashRef[DataProfileSpec()];

declare 'Mode',
    as (Int | Str);

declare 'PostScanActions',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::PostScanActions'];

coerce 'PostScanActions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::PostScanActions'->new($_) };

declare 'RepeatedPostScanActions',
    as ArrayRef[PostScanActions()];

coerce 'RepeatedPostScanActions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::PostScanActions'->new($_) } @$_ ] };

declare 'MapStringPostScanActions',
    as HashRef[PostScanActions()];

declare 'BigQueryExport',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::PostScanActions::BigQueryExport'];

coerce 'BigQueryExport',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::PostScanActions::BigQueryExport'->new($_) };

declare 'RepeatedBigQueryExport',
    as ArrayRef[BigQueryExport()];

coerce 'RepeatedBigQueryExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::PostScanActions::BigQueryExport'->new($_) } @$_ ] };

declare 'MapStringBigQueryExport',
    as HashRef[BigQueryExport()];

declare 'SelectedFields',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::SelectedFields'];

coerce 'SelectedFields',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::SelectedFields'->new($_) };

declare 'RepeatedSelectedFields',
    as ArrayRef[SelectedFields()];

coerce 'RepeatedSelectedFields',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileSpec::SelectedFields'->new($_) } @$_ ] };

declare 'MapStringSelectedFields',
    as HashRef[SelectedFields()];

declare 'DataProfileResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult'];

coerce 'DataProfileResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult'->new($_) };

declare 'RepeatedDataProfileResult',
    as ArrayRef[DataProfileResult()];

coerce 'RepeatedDataProfileResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult'->new($_) } @$_ ] };

declare 'MapStringDataProfileResult',
    as HashRef[DataProfileResult()];

declare 'Profile',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile'];

coerce 'Profile',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile'->new($_) };

declare 'RepeatedProfile',
    as ArrayRef[Profile()];

coerce 'RepeatedProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile'->new($_) } @$_ ] };

declare 'MapStringProfile',
    as HashRef[Profile()];

declare 'Field',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'ProfileInfo',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo'];

coerce 'ProfileInfo',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo'->new($_) };

declare 'RepeatedProfileInfo',
    as ArrayRef[ProfileInfo()];

coerce 'RepeatedProfileInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo'->new($_) } @$_ ] };

declare 'MapStringProfileInfo',
    as HashRef[ProfileInfo()];

declare 'StringFieldInfo',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::StringFieldInfo'];

coerce 'StringFieldInfo',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::StringFieldInfo'->new($_) };

declare 'RepeatedStringFieldInfo',
    as ArrayRef[StringFieldInfo()];

coerce 'RepeatedStringFieldInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::StringFieldInfo'->new($_) } @$_ ] };

declare 'MapStringStringFieldInfo',
    as HashRef[StringFieldInfo()];

declare 'IntegerFieldInfo',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::IntegerFieldInfo'];

coerce 'IntegerFieldInfo',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::IntegerFieldInfo'->new($_) };

declare 'RepeatedIntegerFieldInfo',
    as ArrayRef[IntegerFieldInfo()];

coerce 'RepeatedIntegerFieldInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::IntegerFieldInfo'->new($_) } @$_ ] };

declare 'MapStringIntegerFieldInfo',
    as HashRef[IntegerFieldInfo()];

declare 'DoubleFieldInfo',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::DoubleFieldInfo'];

coerce 'DoubleFieldInfo',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::DoubleFieldInfo'->new($_) };

declare 'RepeatedDoubleFieldInfo',
    as ArrayRef[DoubleFieldInfo()];

coerce 'RepeatedDoubleFieldInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::DoubleFieldInfo'->new($_) } @$_ ] };

declare 'MapStringDoubleFieldInfo',
    as HashRef[DoubleFieldInfo()];

declare 'TopNValue',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::TopNValue'];

coerce 'TopNValue',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::TopNValue'->new($_) };

declare 'RepeatedTopNValue',
    as ArrayRef[TopNValue()];

coerce 'RepeatedTopNValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::Profile::Field::ProfileInfo::TopNValue'->new($_) } @$_ ] };

declare 'MapStringTopNValue',
    as HashRef[TopNValue()];

declare 'PostScanActionsResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::PostScanActionsResult'];

coerce 'PostScanActionsResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::PostScanActionsResult'->new($_) };

declare 'RepeatedPostScanActionsResult',
    as ArrayRef[PostScanActionsResult()];

coerce 'RepeatedPostScanActionsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::PostScanActionsResult'->new($_) } @$_ ] };

declare 'MapStringPostScanActionsResult',
    as HashRef[PostScanActionsResult()];

declare 'BigQueryExportResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::PostScanActionsResult::BigQueryExportResult'];

coerce 'BigQueryExportResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::PostScanActionsResult::BigQueryExportResult'->new($_) };

declare 'RepeatedBigQueryExportResult',
    as ArrayRef[BigQueryExportResult()];

coerce 'RepeatedBigQueryExportResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProfile::DataProfileResult::PostScanActionsResult::BigQueryExportResult'->new($_) } @$_ ] };

declare 'MapStringBigQueryExportResult',
    as HashRef[BigQueryExportResult()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataProfile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
