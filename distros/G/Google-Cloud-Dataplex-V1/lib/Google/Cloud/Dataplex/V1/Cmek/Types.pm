package Google::Cloud::Dataplex::V1::Cmek::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'EncryptionState',
    as (Int | Str);

declare 'FailureDetails',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig::FailureDetails'];

coerce 'FailureDetails',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig::FailureDetails'->new($_) };

declare 'RepeatedFailureDetails',
    as ArrayRef[FailureDetails()];

coerce 'RepeatedFailureDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig::FailureDetails'->new($_) } @$_ ] };

declare 'MapStringFailureDetails',
    as HashRef[FailureDetails()];

declare 'ErrorCode',
    as (Int | Str);

declare 'CreateEncryptionConfigRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest'];

coerce 'CreateEncryptionConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest'->new($_) };

declare 'RepeatedCreateEncryptionConfigRequest',
    as ArrayRef[CreateEncryptionConfigRequest()];

coerce 'RepeatedCreateEncryptionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEncryptionConfigRequest',
    as HashRef[CreateEncryptionConfigRequest()];

declare 'GetEncryptionConfigRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest'];

coerce 'GetEncryptionConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest'->new($_) };

declare 'RepeatedGetEncryptionConfigRequest',
    as ArrayRef[GetEncryptionConfigRequest()];

coerce 'RepeatedGetEncryptionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetEncryptionConfigRequest',
    as HashRef[GetEncryptionConfigRequest()];

declare 'UpdateEncryptionConfigRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest'];

coerce 'UpdateEncryptionConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest'->new($_) };

declare 'RepeatedUpdateEncryptionConfigRequest',
    as ArrayRef[UpdateEncryptionConfigRequest()];

coerce 'RepeatedUpdateEncryptionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEncryptionConfigRequest',
    as HashRef[UpdateEncryptionConfigRequest()];

declare 'DeleteEncryptionConfigRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest'];

coerce 'DeleteEncryptionConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest'->new($_) };

declare 'RepeatedDeleteEncryptionConfigRequest',
    as ArrayRef[DeleteEncryptionConfigRequest()];

coerce 'RepeatedDeleteEncryptionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEncryptionConfigRequest',
    as HashRef[DeleteEncryptionConfigRequest()];

declare 'ListEncryptionConfigsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest'];

coerce 'ListEncryptionConfigsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest'->new($_) };

declare 'RepeatedListEncryptionConfigsRequest',
    as ArrayRef[ListEncryptionConfigsRequest()];

coerce 'RepeatedListEncryptionConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListEncryptionConfigsRequest',
    as HashRef[ListEncryptionConfigsRequest()];

declare 'ListEncryptionConfigsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse'];

coerce 'ListEncryptionConfigsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse'->new($_) };

declare 'RepeatedListEncryptionConfigsResponse',
    as ArrayRef[ListEncryptionConfigsResponse()];

coerce 'RepeatedListEncryptionConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListEncryptionConfigsResponse',
    as HashRef[ListEncryptionConfigsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
