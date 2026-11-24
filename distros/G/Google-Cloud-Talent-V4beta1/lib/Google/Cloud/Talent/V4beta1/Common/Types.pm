package Google::Cloud::Talent::V4beta1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompanySize',
    as (Int | Str);

declare 'JobBenefit',
    as (Int | Str);

declare 'DegreeType',
    as (Int | Str);

declare 'EmploymentType',
    as (Int | Str);

declare 'JobLevel',
    as (Int | Str);

declare 'JobCategory',
    as (Int | Str);

declare 'PostingRegion',
    as (Int | Str);

declare 'Visibility',
    as (Int | Str);

declare 'HtmlSanitization',
    as (Int | Str);

declare 'CommuteMethod',
    as (Int | Str);

declare 'TimestampRange',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::TimestampRange'];

coerce 'TimestampRange',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::TimestampRange'->new($_) };

declare 'RepeatedTimestampRange',
    as ArrayRef[TimestampRange()];

coerce 'RepeatedTimestampRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::TimestampRange'->new($_) } @$_ ] };

declare 'MapStringTimestampRange',
    as HashRef[TimestampRange()];

declare 'Location',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'LocationType',
    as (Int | Str);

declare 'RequestMetadata',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::RequestMetadata'];

coerce 'RequestMetadata',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::RequestMetadata'->new($_) };

declare 'RepeatedRequestMetadata',
    as ArrayRef[RequestMetadata()];

coerce 'RepeatedRequestMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::RequestMetadata'->new($_) } @$_ ] };

declare 'MapStringRequestMetadata',
    as HashRef[RequestMetadata()];

declare 'ResponseMetadata',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::ResponseMetadata'];

coerce 'ResponseMetadata',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::ResponseMetadata'->new($_) };

declare 'RepeatedResponseMetadata',
    as ArrayRef[ResponseMetadata()];

coerce 'RepeatedResponseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::ResponseMetadata'->new($_) } @$_ ] };

declare 'MapStringResponseMetadata',
    as HashRef[ResponseMetadata()];

declare 'DeviceInfo',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::DeviceInfo'];

coerce 'DeviceInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::DeviceInfo'->new($_) };

declare 'RepeatedDeviceInfo',
    as ArrayRef[DeviceInfo()];

coerce 'RepeatedDeviceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::DeviceInfo'->new($_) } @$_ ] };

declare 'MapStringDeviceInfo',
    as HashRef[DeviceInfo()];

declare 'DeviceType',
    as (Int | Str);

declare 'CustomAttribute',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::CustomAttribute'];

coerce 'CustomAttribute',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::CustomAttribute'->new($_) };

declare 'RepeatedCustomAttribute',
    as ArrayRef[CustomAttribute()];

coerce 'RepeatedCustomAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::CustomAttribute'->new($_) } @$_ ] };

declare 'MapStringCustomAttribute',
    as HashRef[CustomAttribute()];

declare 'SpellingCorrection',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::SpellingCorrection'];

coerce 'SpellingCorrection',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::SpellingCorrection'->new($_) };

declare 'RepeatedSpellingCorrection',
    as ArrayRef[SpellingCorrection()];

coerce 'RepeatedSpellingCorrection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::SpellingCorrection'->new($_) } @$_ ] };

declare 'MapStringSpellingCorrection',
    as HashRef[SpellingCorrection()];

declare 'CompensationInfo',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::CompensationInfo'];

coerce 'CompensationInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::CompensationInfo'->new($_) };

declare 'RepeatedCompensationInfo',
    as ArrayRef[CompensationInfo()];

coerce 'RepeatedCompensationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::CompensationInfo'->new($_) } @$_ ] };

declare 'MapStringCompensationInfo',
    as HashRef[CompensationInfo()];

declare 'CompensationType',
    as (Int | Str);

declare 'CompensationUnit',
    as (Int | Str);

declare 'CompensationEntry',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationEntry'];

coerce 'CompensationEntry',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationEntry'->new($_) };

declare 'RepeatedCompensationEntry',
    as ArrayRef[CompensationEntry()];

coerce 'RepeatedCompensationEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationEntry'->new($_) } @$_ ] };

declare 'MapStringCompensationEntry',
    as HashRef[CompensationEntry()];

declare 'CompensationRange',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationRange'];

coerce 'CompensationRange',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationRange'->new($_) };

declare 'RepeatedCompensationRange',
    as ArrayRef[CompensationRange()];

coerce 'RepeatedCompensationRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationRange'->new($_) } @$_ ] };

declare 'MapStringCompensationRange',
    as HashRef[CompensationRange()];

declare 'BatchOperationMetadata',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Common::BatchOperationMetadata'];

coerce 'BatchOperationMetadata',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Common::BatchOperationMetadata'->new($_) };

declare 'RepeatedBatchOperationMetadata',
    as ArrayRef[BatchOperationMetadata()];

coerce 'RepeatedBatchOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Common::BatchOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchOperationMetadata',
    as HashRef[BatchOperationMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
