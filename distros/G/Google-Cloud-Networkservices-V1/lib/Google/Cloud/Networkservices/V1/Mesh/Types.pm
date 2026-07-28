package Google::Cloud::Networkservices::V1::Mesh::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Mesh',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::Mesh'];

coerce 'Mesh',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::Mesh'->new($_) };

declare 'RepeatedMesh',
    as ArrayRef[Mesh()];

coerce 'RepeatedMesh',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::Mesh'->new($_) } @$_ ] };

declare 'MapStringMesh',
    as HashRef[Mesh()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::Mesh::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::Mesh::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::Mesh::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListMeshesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::ListMeshesRequest'];

coerce 'ListMeshesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::ListMeshesRequest'->new($_) };

declare 'RepeatedListMeshesRequest',
    as ArrayRef[ListMeshesRequest()];

coerce 'RepeatedListMeshesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::ListMeshesRequest'->new($_) } @$_ ] };

declare 'MapStringListMeshesRequest',
    as HashRef[ListMeshesRequest()];

declare 'ListMeshesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::ListMeshesResponse'];

coerce 'ListMeshesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::ListMeshesResponse'->new($_) };

declare 'RepeatedListMeshesResponse',
    as ArrayRef[ListMeshesResponse()];

coerce 'RepeatedListMeshesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::ListMeshesResponse'->new($_) } @$_ ] };

declare 'MapStringListMeshesResponse',
    as HashRef[ListMeshesResponse()];

declare 'GetMeshRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::GetMeshRequest'];

coerce 'GetMeshRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::GetMeshRequest'->new($_) };

declare 'RepeatedGetMeshRequest',
    as ArrayRef[GetMeshRequest()];

coerce 'RepeatedGetMeshRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::GetMeshRequest'->new($_) } @$_ ] };

declare 'MapStringGetMeshRequest',
    as HashRef[GetMeshRequest()];

declare 'CreateMeshRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::CreateMeshRequest'];

coerce 'CreateMeshRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::CreateMeshRequest'->new($_) };

declare 'RepeatedCreateMeshRequest',
    as ArrayRef[CreateMeshRequest()];

coerce 'RepeatedCreateMeshRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::CreateMeshRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMeshRequest',
    as HashRef[CreateMeshRequest()];

declare 'UpdateMeshRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::UpdateMeshRequest'];

coerce 'UpdateMeshRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::UpdateMeshRequest'->new($_) };

declare 'RepeatedUpdateMeshRequest',
    as ArrayRef[UpdateMeshRequest()];

coerce 'RepeatedUpdateMeshRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::UpdateMeshRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMeshRequest',
    as HashRef[UpdateMeshRequest()];

declare 'DeleteMeshRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Mesh::DeleteMeshRequest'];

coerce 'DeleteMeshRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Mesh::DeleteMeshRequest'->new($_) };

declare 'RepeatedDeleteMeshRequest',
    as ArrayRef[DeleteMeshRequest()];

coerce 'RepeatedDeleteMeshRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Mesh::DeleteMeshRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMeshRequest',
    as HashRef[DeleteMeshRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
