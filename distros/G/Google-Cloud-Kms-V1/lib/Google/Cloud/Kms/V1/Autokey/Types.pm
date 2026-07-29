package Google::Cloud::Kms::V1::Autokey::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateKeyHandleRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest'];

coerce 'CreateKeyHandleRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest'->new($_) };

declare 'RepeatedCreateKeyHandleRequest',
    as ArrayRef[CreateKeyHandleRequest()];

coerce 'RepeatedCreateKeyHandleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateKeyHandleRequest',
    as HashRef[CreateKeyHandleRequest()];

declare 'GetKeyHandleRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Autokey::GetKeyHandleRequest'];

coerce 'GetKeyHandleRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Autokey::GetKeyHandleRequest'->new($_) };

declare 'RepeatedGetKeyHandleRequest',
    as ArrayRef[GetKeyHandleRequest()];

coerce 'RepeatedGetKeyHandleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Autokey::GetKeyHandleRequest'->new($_) } @$_ ] };

declare 'MapStringGetKeyHandleRequest',
    as HashRef[GetKeyHandleRequest()];

declare 'KeyHandle',
    as InstanceOf['Google::Cloud::Kms::V1::Autokey::KeyHandle'];

coerce 'KeyHandle',
    from HashRef, via { 'Google::Cloud::Kms::V1::Autokey::KeyHandle'->new($_) };

declare 'RepeatedKeyHandle',
    as ArrayRef[KeyHandle()];

coerce 'RepeatedKeyHandle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Autokey::KeyHandle'->new($_) } @$_ ] };

declare 'MapStringKeyHandle',
    as HashRef[KeyHandle()];

declare 'CreateKeyHandleMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::Autokey::CreateKeyHandleMetadata'];

coerce 'CreateKeyHandleMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::Autokey::CreateKeyHandleMetadata'->new($_) };

declare 'RepeatedCreateKeyHandleMetadata',
    as ArrayRef[CreateKeyHandleMetadata()];

coerce 'RepeatedCreateKeyHandleMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Autokey::CreateKeyHandleMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateKeyHandleMetadata',
    as HashRef[CreateKeyHandleMetadata()];

declare 'ListKeyHandlesRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Autokey::ListKeyHandlesRequest'];

coerce 'ListKeyHandlesRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Autokey::ListKeyHandlesRequest'->new($_) };

declare 'RepeatedListKeyHandlesRequest',
    as ArrayRef[ListKeyHandlesRequest()];

coerce 'RepeatedListKeyHandlesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Autokey::ListKeyHandlesRequest'->new($_) } @$_ ] };

declare 'MapStringListKeyHandlesRequest',
    as HashRef[ListKeyHandlesRequest()];

declare 'ListKeyHandlesResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Autokey::ListKeyHandlesResponse'];

coerce 'ListKeyHandlesResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Autokey::ListKeyHandlesResponse'->new($_) };

declare 'RepeatedListKeyHandlesResponse',
    as ArrayRef[ListKeyHandlesResponse()];

coerce 'RepeatedListKeyHandlesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Autokey::ListKeyHandlesResponse'->new($_) } @$_ ] };

declare 'MapStringListKeyHandlesResponse',
    as HashRef[ListKeyHandlesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::Autokey::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
