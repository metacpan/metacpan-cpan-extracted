package Google::Cloud::Run::V2::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Run::V2::Instance::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'StopInstanceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::StopInstanceRequest'];

coerce 'StopInstanceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::StopInstanceRequest'->new($_) };

declare 'RepeatedStopInstanceRequest',
    as ArrayRef[StopInstanceRequest()];

coerce 'RepeatedStopInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::StopInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStopInstanceRequest',
    as HashRef[StopInstanceRequest()];

declare 'StartInstanceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Instance::StartInstanceRequest'];

coerce 'StartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::StartInstanceRequest'->new($_) };

declare 'RepeatedStartInstanceRequest',
    as ArrayRef[StartInstanceRequest()];

coerce 'RepeatedStartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::StartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStartInstanceRequest',
    as HashRef[StartInstanceRequest()];

declare 'Instance',
    as InstanceOf['Google::Cloud::Run::V2::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'RestartPolicy',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Instance::Instance::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Instance::Instance::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Instance::Instance::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
