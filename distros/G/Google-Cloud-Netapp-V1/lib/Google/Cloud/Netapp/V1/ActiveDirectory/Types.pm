package Google::Cloud::Netapp::V1::ActiveDirectory::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListActiveDirectoriesRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest'];

coerce 'ListActiveDirectoriesRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest'->new($_) };

declare 'RepeatedListActiveDirectoriesRequest',
    as ArrayRef[ListActiveDirectoriesRequest()];

coerce 'RepeatedListActiveDirectoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListActiveDirectoriesRequest',
    as HashRef[ListActiveDirectoriesRequest()];

declare 'ListActiveDirectoriesResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesResponse'];

coerce 'ListActiveDirectoriesResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesResponse'->new($_) };

declare 'RepeatedListActiveDirectoriesResponse',
    as ArrayRef[ListActiveDirectoriesResponse()];

coerce 'RepeatedListActiveDirectoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListActiveDirectoriesResponse',
    as HashRef[ListActiveDirectoriesResponse()];

declare 'GetActiveDirectoryRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::GetActiveDirectoryRequest'];

coerce 'GetActiveDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::GetActiveDirectoryRequest'->new($_) };

declare 'RepeatedGetActiveDirectoryRequest',
    as ArrayRef[GetActiveDirectoryRequest()];

coerce 'RepeatedGetActiveDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::GetActiveDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetActiveDirectoryRequest',
    as HashRef[GetActiveDirectoryRequest()];

declare 'CreateActiveDirectoryRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::CreateActiveDirectoryRequest'];

coerce 'CreateActiveDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::CreateActiveDirectoryRequest'->new($_) };

declare 'RepeatedCreateActiveDirectoryRequest',
    as ArrayRef[CreateActiveDirectoryRequest()];

coerce 'RepeatedCreateActiveDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::CreateActiveDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateActiveDirectoryRequest',
    as HashRef[CreateActiveDirectoryRequest()];

declare 'UpdateActiveDirectoryRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::UpdateActiveDirectoryRequest'];

coerce 'UpdateActiveDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::UpdateActiveDirectoryRequest'->new($_) };

declare 'RepeatedUpdateActiveDirectoryRequest',
    as ArrayRef[UpdateActiveDirectoryRequest()];

coerce 'RepeatedUpdateActiveDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::UpdateActiveDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateActiveDirectoryRequest',
    as HashRef[UpdateActiveDirectoryRequest()];

declare 'DeleteActiveDirectoryRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::DeleteActiveDirectoryRequest'];

coerce 'DeleteActiveDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::DeleteActiveDirectoryRequest'->new($_) };

declare 'RepeatedDeleteActiveDirectoryRequest',
    as ArrayRef[DeleteActiveDirectoryRequest()];

coerce 'RepeatedDeleteActiveDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::DeleteActiveDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteActiveDirectoryRequest',
    as HashRef[DeleteActiveDirectoryRequest()];

declare 'ActiveDirectory',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory'];

coerce 'ActiveDirectory',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory'->new($_) };

declare 'RepeatedActiveDirectory',
    as ArrayRef[ActiveDirectory()];

coerce 'RepeatedActiveDirectory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory'->new($_) } @$_ ] };

declare 'MapStringActiveDirectory',
    as HashRef[ActiveDirectory()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::ActiveDirectory::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
