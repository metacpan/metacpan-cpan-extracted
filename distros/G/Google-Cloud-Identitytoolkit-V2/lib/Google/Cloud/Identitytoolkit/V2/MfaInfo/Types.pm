package Google::Cloud::Identitytoolkit::V2::MfaInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutoRetrievalInfo',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo'];

coerce 'AutoRetrievalInfo',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo'->new($_) };

declare 'RepeatedAutoRetrievalInfo',
    as ArrayRef[AutoRetrievalInfo()];

coerce 'RepeatedAutoRetrievalInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo'->new($_) } @$_ ] };

declare 'MapStringAutoRetrievalInfo',
    as HashRef[AutoRetrievalInfo()];

declare 'StartMfaPhoneRequestInfo',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo'];

coerce 'StartMfaPhoneRequestInfo',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo'->new($_) };

declare 'RepeatedStartMfaPhoneRequestInfo',
    as ArrayRef[StartMfaPhoneRequestInfo()];

coerce 'RepeatedStartMfaPhoneRequestInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo'->new($_) } @$_ ] };

declare 'MapStringStartMfaPhoneRequestInfo',
    as HashRef[StartMfaPhoneRequestInfo()];

declare 'StartMfaPhoneResponseInfo',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo'];

coerce 'StartMfaPhoneResponseInfo',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo'->new($_) };

declare 'RepeatedStartMfaPhoneResponseInfo',
    as ArrayRef[StartMfaPhoneResponseInfo()];

coerce 'RepeatedStartMfaPhoneResponseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo'->new($_) } @$_ ] };

declare 'MapStringStartMfaPhoneResponseInfo',
    as HashRef[StartMfaPhoneResponseInfo()];

declare 'FinalizeMfaPhoneRequestInfo',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo'];

coerce 'FinalizeMfaPhoneRequestInfo',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo'->new($_) };

declare 'RepeatedFinalizeMfaPhoneRequestInfo',
    as ArrayRef[FinalizeMfaPhoneRequestInfo()];

coerce 'RepeatedFinalizeMfaPhoneRequestInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo'->new($_) } @$_ ] };

declare 'MapStringFinalizeMfaPhoneRequestInfo',
    as HashRef[FinalizeMfaPhoneRequestInfo()];

declare 'FinalizeMfaPhoneResponseInfo',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo'];

coerce 'FinalizeMfaPhoneResponseInfo',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo'->new($_) };

declare 'RepeatedFinalizeMfaPhoneResponseInfo',
    as ArrayRef[FinalizeMfaPhoneResponseInfo()];

coerce 'RepeatedFinalizeMfaPhoneResponseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo'->new($_) } @$_ ] };

declare 'MapStringFinalizeMfaPhoneResponseInfo',
    as HashRef[FinalizeMfaPhoneResponseInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Identitytoolkit::V2::MfaInfo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
