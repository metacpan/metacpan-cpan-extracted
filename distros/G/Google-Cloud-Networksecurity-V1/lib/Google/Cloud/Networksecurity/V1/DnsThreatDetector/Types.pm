package Google::Cloud::Networksecurity::V1::DnsThreatDetector::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DnsThreatDetector',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector'];

coerce 'DnsThreatDetector',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector'->new($_) };

declare 'RepeatedDnsThreatDetector',
    as ArrayRef[DnsThreatDetector()];

coerce 'RepeatedDnsThreatDetector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector'->new($_) } @$_ ] };

declare 'MapStringDnsThreatDetector',
    as HashRef[DnsThreatDetector()];

declare 'Provider',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListDnsThreatDetectorsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest'];

coerce 'ListDnsThreatDetectorsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest'->new($_) };

declare 'RepeatedListDnsThreatDetectorsRequest',
    as ArrayRef[ListDnsThreatDetectorsRequest()];

coerce 'RepeatedListDnsThreatDetectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListDnsThreatDetectorsRequest',
    as HashRef[ListDnsThreatDetectorsRequest()];

declare 'ListDnsThreatDetectorsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse'];

coerce 'ListDnsThreatDetectorsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse'->new($_) };

declare 'RepeatedListDnsThreatDetectorsResponse',
    as ArrayRef[ListDnsThreatDetectorsResponse()];

coerce 'RepeatedListDnsThreatDetectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListDnsThreatDetectorsResponse',
    as HashRef[ListDnsThreatDetectorsResponse()];

declare 'GetDnsThreatDetectorRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest'];

coerce 'GetDnsThreatDetectorRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest'->new($_) };

declare 'RepeatedGetDnsThreatDetectorRequest',
    as ArrayRef[GetDnsThreatDetectorRequest()];

coerce 'RepeatedGetDnsThreatDetectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetDnsThreatDetectorRequest',
    as HashRef[GetDnsThreatDetectorRequest()];

declare 'CreateDnsThreatDetectorRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest'];

coerce 'CreateDnsThreatDetectorRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest'->new($_) };

declare 'RepeatedCreateDnsThreatDetectorRequest',
    as ArrayRef[CreateDnsThreatDetectorRequest()];

coerce 'RepeatedCreateDnsThreatDetectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDnsThreatDetectorRequest',
    as HashRef[CreateDnsThreatDetectorRequest()];

declare 'UpdateDnsThreatDetectorRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest'];

coerce 'UpdateDnsThreatDetectorRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest'->new($_) };

declare 'RepeatedUpdateDnsThreatDetectorRequest',
    as ArrayRef[UpdateDnsThreatDetectorRequest()];

coerce 'RepeatedUpdateDnsThreatDetectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDnsThreatDetectorRequest',
    as HashRef[UpdateDnsThreatDetectorRequest()];

declare 'DeleteDnsThreatDetectorRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest'];

coerce 'DeleteDnsThreatDetectorRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest'->new($_) };

declare 'RepeatedDeleteDnsThreatDetectorRequest',
    as ArrayRef[DeleteDnsThreatDetectorRequest()];

coerce 'RepeatedDeleteDnsThreatDetectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDnsThreatDetectorRequest',
    as HashRef[DeleteDnsThreatDetectorRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
