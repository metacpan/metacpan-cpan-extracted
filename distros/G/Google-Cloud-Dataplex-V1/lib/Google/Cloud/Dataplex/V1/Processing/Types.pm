package Google::Cloud::Dataplex::V1::Processing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Trigger',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::Trigger'];

coerce 'Trigger',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::Trigger'->new($_) };

declare 'RepeatedTrigger',
    as ArrayRef[Trigger()];

coerce 'RepeatedTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::Trigger'->new($_) } @$_ ] };

declare 'MapStringTrigger',
    as HashRef[Trigger()];

declare 'OnDemand',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::Trigger::OnDemand'];

coerce 'OnDemand',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::Trigger::OnDemand'->new($_) };

declare 'RepeatedOnDemand',
    as ArrayRef[OnDemand()];

coerce 'RepeatedOnDemand',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::Trigger::OnDemand'->new($_) } @$_ ] };

declare 'MapStringOnDemand',
    as HashRef[OnDemand()];

declare 'Schedule',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::Trigger::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::Trigger::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::Trigger::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'OneTime',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::Trigger::OneTime'];

coerce 'OneTime',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::Trigger::OneTime'->new($_) };

declare 'RepeatedOneTime',
    as ArrayRef[OneTime()];

coerce 'RepeatedOneTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::Trigger::OneTime'->new($_) } @$_ ] };

declare 'MapStringOneTime',
    as HashRef[OneTime()];

declare 'DataSource',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::DataSource'];

coerce 'DataSource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::DataSource'->new($_) };

declare 'RepeatedDataSource',
    as ArrayRef[DataSource()];

coerce 'RepeatedDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::DataSource'->new($_) } @$_ ] };

declare 'MapStringDataSource',
    as HashRef[DataSource()];

declare 'ScannedData',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::ScannedData'];

coerce 'ScannedData',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::ScannedData'->new($_) };

declare 'RepeatedScannedData',
    as ArrayRef[ScannedData()];

coerce 'RepeatedScannedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::ScannedData'->new($_) } @$_ ] };

declare 'MapStringScannedData',
    as HashRef[ScannedData()];

declare 'IncrementalField',
    as InstanceOf['Google::Cloud::Dataplex::V1::Processing::ScannedData::IncrementalField'];

coerce 'IncrementalField',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Processing::ScannedData::IncrementalField'->new($_) };

declare 'RepeatedIncrementalField',
    as ArrayRef[IncrementalField()];

coerce 'RepeatedIncrementalField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Processing::ScannedData::IncrementalField'->new($_) } @$_ ] };

declare 'MapStringIncrementalField',
    as HashRef[IncrementalField()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Processing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
