package Google::Cloud::Discoveryengine::V1::EngineService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest'];

coerce 'CreateEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest'->new($_) };

declare 'RepeatedCreateEngineRequest',
    as ArrayRef[CreateEngineRequest()];

coerce 'RepeatedCreateEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEngineRequest',
    as HashRef[CreateEngineRequest()];

declare 'CreateEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineMetadata'];

coerce 'CreateEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineMetadata'->new($_) };

declare 'RepeatedCreateEngineMetadata',
    as ArrayRef[CreateEngineMetadata()];

coerce 'RepeatedCreateEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateEngineMetadata',
    as HashRef[CreateEngineMetadata()];

declare 'DeleteEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineRequest'];

coerce 'DeleteEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineRequest'->new($_) };

declare 'RepeatedDeleteEngineRequest',
    as ArrayRef[DeleteEngineRequest()];

coerce 'RepeatedDeleteEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEngineRequest',
    as HashRef[DeleteEngineRequest()];

declare 'DeleteEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineMetadata'];

coerce 'DeleteEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineMetadata'->new($_) };

declare 'RepeatedDeleteEngineMetadata',
    as ArrayRef[DeleteEngineMetadata()];

coerce 'RepeatedDeleteEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteEngineMetadata',
    as HashRef[DeleteEngineMetadata()];

declare 'GetEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::GetEngineRequest'];

coerce 'GetEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::GetEngineRequest'->new($_) };

declare 'RepeatedGetEngineRequest',
    as ArrayRef[GetEngineRequest()];

coerce 'RepeatedGetEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::GetEngineRequest'->new($_) } @$_ ] };

declare 'MapStringGetEngineRequest',
    as HashRef[GetEngineRequest()];

declare 'ListEnginesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesRequest'];

coerce 'ListEnginesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesRequest'->new($_) };

declare 'RepeatedListEnginesRequest',
    as ArrayRef[ListEnginesRequest()];

coerce 'RepeatedListEnginesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesRequest'->new($_) } @$_ ] };

declare 'MapStringListEnginesRequest',
    as HashRef[ListEnginesRequest()];

declare 'ListEnginesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesResponse'];

coerce 'ListEnginesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesResponse'->new($_) };

declare 'RepeatedListEnginesResponse',
    as ArrayRef[ListEnginesResponse()];

coerce 'RepeatedListEnginesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesResponse'->new($_) } @$_ ] };

declare 'MapStringListEnginesResponse',
    as HashRef[ListEnginesResponse()];

declare 'UpdateEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::EngineService::UpdateEngineRequest'];

coerce 'UpdateEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::EngineService::UpdateEngineRequest'->new($_) };

declare 'RepeatedUpdateEngineRequest',
    as ArrayRef[UpdateEngineRequest()];

coerce 'RepeatedUpdateEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::EngineService::UpdateEngineRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEngineRequest',
    as HashRef[UpdateEngineRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::EngineService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
