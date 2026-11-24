package Google::Cloud::Ftp::Logging::V1::FtpEvents::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FtpEvent',
    as InstanceOf['Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent'];

coerce 'FtpEvent',
    from HashRef, via { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent'->new($_) };

declare 'RepeatedFtpEvent',
    as ArrayRef[FtpEvent()];

coerce 'RepeatedFtpEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent'->new($_) } @$_ ] };

declare 'MapStringFtpEvent',
    as HashRef[FtpEvent()];

declare 'EventType',
    as (Int | Str);

declare 'AuthDetails',
    as InstanceOf['Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::AuthDetails'];

coerce 'AuthDetails',
    from HashRef, via { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::AuthDetails'->new($_) };

declare 'RepeatedAuthDetails',
    as ArrayRef[AuthDetails()];

coerce 'RepeatedAuthDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::AuthDetails'->new($_) } @$_ ] };

declare 'MapStringAuthDetails',
    as HashRef[AuthDetails()];

declare 'AuthMethod',
    as (Int | Str);

declare 'DisconnectReason',
    as (Int | Str);

declare 'CommandDetails',
    as InstanceOf['Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::CommandDetails'];

coerce 'CommandDetails',
    from HashRef, via { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::CommandDetails'->new($_) };

declare 'RepeatedCommandDetails',
    as ArrayRef[CommandDetails()];

coerce 'RepeatedCommandDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::CommandDetails'->new($_) } @$_ ] };

declare 'MapStringCommandDetails',
    as HashRef[CommandDetails()];

declare 'SftpStatusCode',
    as (Int | Str);

declare 'TransferDetails',
    as InstanceOf['Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::TransferDetails'];

coerce 'TransferDetails',
    from HashRef, via { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::TransferDetails'->new($_) };

declare 'RepeatedTransferDetails',
    as ArrayRef[TransferDetails()];

coerce 'RepeatedTransferDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::Logging::V1::FtpEvents::FtpEvent::TransferDetails'->new($_) } @$_ ] };

declare 'MapStringTransferDetails',
    as HashRef[TransferDetails()];

declare 'TransferType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ftp::Logging::V1::FtpEvents::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
