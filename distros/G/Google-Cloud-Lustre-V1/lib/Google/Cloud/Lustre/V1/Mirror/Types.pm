package Google::Cloud::Lustre::V1::Mirror::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Mirror',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::Mirror'];

coerce 'Mirror',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::Mirror'->new($_) };

declare 'RepeatedMirror',
    as ArrayRef[Mirror()];

coerce 'RepeatedMirror',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::Mirror'->new($_) } @$_ ] };

declare 'MapStringMirror',
    as HashRef[Mirror()];

declare 'Direction',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::Mirror::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::Mirror::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::Mirror::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateMirrorRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::CreateMirrorRequest'];

coerce 'CreateMirrorRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::CreateMirrorRequest'->new($_) };

declare 'RepeatedCreateMirrorRequest',
    as ArrayRef[CreateMirrorRequest()];

coerce 'RepeatedCreateMirrorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::CreateMirrorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMirrorRequest',
    as HashRef[CreateMirrorRequest()];

declare 'UpdateMirrorRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::UpdateMirrorRequest'];

coerce 'UpdateMirrorRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::UpdateMirrorRequest'->new($_) };

declare 'RepeatedUpdateMirrorRequest',
    as ArrayRef[UpdateMirrorRequest()];

coerce 'RepeatedUpdateMirrorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::UpdateMirrorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMirrorRequest',
    as HashRef[UpdateMirrorRequest()];

declare 'DeleteMirrorRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::DeleteMirrorRequest'];

coerce 'DeleteMirrorRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::DeleteMirrorRequest'->new($_) };

declare 'RepeatedDeleteMirrorRequest',
    as ArrayRef[DeleteMirrorRequest()];

coerce 'RepeatedDeleteMirrorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::DeleteMirrorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMirrorRequest',
    as HashRef[DeleteMirrorRequest()];

declare 'GetMirrorRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::GetMirrorRequest'];

coerce 'GetMirrorRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::GetMirrorRequest'->new($_) };

declare 'RepeatedGetMirrorRequest',
    as ArrayRef[GetMirrorRequest()];

coerce 'RepeatedGetMirrorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::GetMirrorRequest'->new($_) } @$_ ] };

declare 'MapStringGetMirrorRequest',
    as HashRef[GetMirrorRequest()];

declare 'ListMirrorsRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::ListMirrorsRequest'];

coerce 'ListMirrorsRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::ListMirrorsRequest'->new($_) };

declare 'RepeatedListMirrorsRequest',
    as ArrayRef[ListMirrorsRequest()];

coerce 'RepeatedListMirrorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::ListMirrorsRequest'->new($_) } @$_ ] };

declare 'MapStringListMirrorsRequest',
    as HashRef[ListMirrorsRequest()];

declare 'ListMirrorsResponse',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::ListMirrorsResponse'];

coerce 'ListMirrorsResponse',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::ListMirrorsResponse'->new($_) };

declare 'RepeatedListMirrorsResponse',
    as ArrayRef[ListMirrorsResponse()];

coerce 'RepeatedListMirrorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::ListMirrorsResponse'->new($_) } @$_ ] };

declare 'MapStringListMirrorsResponse',
    as HashRef[ListMirrorsResponse()];

declare 'CreateMirrorMetadata',
    as InstanceOf['Google::Cloud::Lustre::V1::Mirror::CreateMirrorMetadata'];

coerce 'CreateMirrorMetadata',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Mirror::CreateMirrorMetadata'->new($_) };

declare 'RepeatedCreateMirrorMetadata',
    as ArrayRef[CreateMirrorMetadata()];

coerce 'RepeatedCreateMirrorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Mirror::CreateMirrorMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateMirrorMetadata',
    as HashRef[CreateMirrorMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Lustre::V1::Mirror::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
