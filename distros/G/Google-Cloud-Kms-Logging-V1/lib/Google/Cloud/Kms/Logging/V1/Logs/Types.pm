package Google::Cloud::Kms::Logging::V1::Logs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CryptoKeyEvent',
    as InstanceOf['Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent'];

coerce 'CryptoKeyEvent',
    from HashRef, via { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent'->new($_) };

declare 'RepeatedCryptoKeyEvent',
    as ArrayRef[CryptoKeyEvent()];

coerce 'RepeatedCryptoKeyEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyEvent',
    as HashRef[CryptoKeyEvent()];

declare 'RotationEvent',
    as InstanceOf['Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent::RotationEvent'];

coerce 'RotationEvent',
    from HashRef, via { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent::RotationEvent'->new($_) };

declare 'RepeatedRotationEvent',
    as ArrayRef[RotationEvent()];

coerce 'RepeatedRotationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent::RotationEvent'->new($_) } @$_ ] };

declare 'MapStringRotationEvent',
    as HashRef[RotationEvent()];

declare 'CryptoKeyVersionEvent',
    as InstanceOf['Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent'];

coerce 'CryptoKeyVersionEvent',
    from HashRef, via { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent'->new($_) };

declare 'RepeatedCryptoKeyVersionEvent',
    as ArrayRef[CryptoKeyVersionEvent()];

coerce 'RepeatedCryptoKeyVersionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyVersionEvent',
    as HashRef[CryptoKeyVersionEvent()];

declare 'ScheduledDestructionEvent',
    as InstanceOf['Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ScheduledDestructionEvent'];

coerce 'ScheduledDestructionEvent',
    from HashRef, via { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ScheduledDestructionEvent'->new($_) };

declare 'RepeatedScheduledDestructionEvent',
    as ArrayRef[ScheduledDestructionEvent()];

coerce 'RepeatedScheduledDestructionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ScheduledDestructionEvent'->new($_) } @$_ ] };

declare 'MapStringScheduledDestructionEvent',
    as HashRef[ScheduledDestructionEvent()];

declare 'KeyGenerationEvent',
    as InstanceOf['Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::KeyGenerationEvent'];

coerce 'KeyGenerationEvent',
    from HashRef, via { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::KeyGenerationEvent'->new($_) };

declare 'RepeatedKeyGenerationEvent',
    as ArrayRef[KeyGenerationEvent()];

coerce 'RepeatedKeyGenerationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::KeyGenerationEvent'->new($_) } @$_ ] };

declare 'MapStringKeyGenerationEvent',
    as HashRef[KeyGenerationEvent()];

declare 'ImportEvent',
    as InstanceOf['Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ImportEvent'];

coerce 'ImportEvent',
    from HashRef, via { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ImportEvent'->new($_) };

declare 'RepeatedImportEvent',
    as ArrayRef[ImportEvent()];

coerce 'RepeatedImportEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ImportEvent'->new($_) } @$_ ] };

declare 'MapStringImportEvent',
    as HashRef[ImportEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::Logging::V1::Logs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
