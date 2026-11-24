package Google::Cloud::Baremetalsolution::V2::NfsShare::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NfsShare',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare'];

coerce 'NfsShare',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare'->new($_) };

declare 'RepeatedNfsShare',
    as ArrayRef[NfsShare()];

coerce 'RepeatedNfsShare',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare'->new($_) } @$_ ] };

declare 'MapStringNfsShare',
    as HashRef[NfsShare()];

declare 'State',
    as (Int | Str);

declare 'MountPermissions',
    as (Int | Str);

declare 'StorageType',
    as (Int | Str);

declare 'AllowedClient',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::AllowedClient'];

coerce 'AllowedClient',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::AllowedClient'->new($_) };

declare 'RepeatedAllowedClient',
    as ArrayRef[AllowedClient()];

coerce 'RepeatedAllowedClient',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::AllowedClient'->new($_) } @$_ ] };

declare 'MapStringAllowedClient',
    as HashRef[AllowedClient()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetNfsShareRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::GetNfsShareRequest'];

coerce 'GetNfsShareRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::GetNfsShareRequest'->new($_) };

declare 'RepeatedGetNfsShareRequest',
    as ArrayRef[GetNfsShareRequest()];

coerce 'RepeatedGetNfsShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::GetNfsShareRequest'->new($_) } @$_ ] };

declare 'MapStringGetNfsShareRequest',
    as HashRef[GetNfsShareRequest()];

declare 'ListNfsSharesRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesRequest'];

coerce 'ListNfsSharesRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesRequest'->new($_) };

declare 'RepeatedListNfsSharesRequest',
    as ArrayRef[ListNfsSharesRequest()];

coerce 'RepeatedListNfsSharesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesRequest'->new($_) } @$_ ] };

declare 'MapStringListNfsSharesRequest',
    as HashRef[ListNfsSharesRequest()];

declare 'ListNfsSharesResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesResponse'];

coerce 'ListNfsSharesResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesResponse'->new($_) };

declare 'RepeatedListNfsSharesResponse',
    as ArrayRef[ListNfsSharesResponse()];

coerce 'RepeatedListNfsSharesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesResponse'->new($_) } @$_ ] };

declare 'MapStringListNfsSharesResponse',
    as HashRef[ListNfsSharesResponse()];

declare 'UpdateNfsShareRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::UpdateNfsShareRequest'];

coerce 'UpdateNfsShareRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::UpdateNfsShareRequest'->new($_) };

declare 'RepeatedUpdateNfsShareRequest',
    as ArrayRef[UpdateNfsShareRequest()];

coerce 'RepeatedUpdateNfsShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::UpdateNfsShareRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNfsShareRequest',
    as HashRef[UpdateNfsShareRequest()];

declare 'RenameNfsShareRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::RenameNfsShareRequest'];

coerce 'RenameNfsShareRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::RenameNfsShareRequest'->new($_) };

declare 'RepeatedRenameNfsShareRequest',
    as ArrayRef[RenameNfsShareRequest()];

coerce 'RepeatedRenameNfsShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::RenameNfsShareRequest'->new($_) } @$_ ] };

declare 'MapStringRenameNfsShareRequest',
    as HashRef[RenameNfsShareRequest()];

declare 'CreateNfsShareRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::CreateNfsShareRequest'];

coerce 'CreateNfsShareRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::CreateNfsShareRequest'->new($_) };

declare 'RepeatedCreateNfsShareRequest',
    as ArrayRef[CreateNfsShareRequest()];

coerce 'RepeatedCreateNfsShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::CreateNfsShareRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNfsShareRequest',
    as HashRef[CreateNfsShareRequest()];

declare 'DeleteNfsShareRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::NfsShare::DeleteNfsShareRequest'];

coerce 'DeleteNfsShareRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::NfsShare::DeleteNfsShareRequest'->new($_) };

declare 'RepeatedDeleteNfsShareRequest',
    as ArrayRef[DeleteNfsShareRequest()];

coerce 'RepeatedDeleteNfsShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::NfsShare::DeleteNfsShareRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNfsShareRequest',
    as HashRef[DeleteNfsShareRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::NfsShare::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
