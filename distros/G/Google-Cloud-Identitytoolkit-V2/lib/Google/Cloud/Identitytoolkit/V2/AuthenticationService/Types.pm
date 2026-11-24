package Google::Cloud::Identitytoolkit::V2::AuthenticationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FinalizeMfaSignInRequest',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest'];

coerce 'FinalizeMfaSignInRequest',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest'->new($_) };

declare 'RepeatedFinalizeMfaSignInRequest',
    as ArrayRef[FinalizeMfaSignInRequest()];

coerce 'RepeatedFinalizeMfaSignInRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeMfaSignInRequest',
    as HashRef[FinalizeMfaSignInRequest()];

declare 'FinalizeMfaSignInResponse',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse'];

coerce 'FinalizeMfaSignInResponse',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse'->new($_) };

declare 'RepeatedFinalizeMfaSignInResponse',
    as ArrayRef[FinalizeMfaSignInResponse()];

coerce 'RepeatedFinalizeMfaSignInResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeMfaSignInResponse',
    as HashRef[FinalizeMfaSignInResponse()];

declare 'StartMfaSignInRequest',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest'];

coerce 'StartMfaSignInRequest',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest'->new($_) };

declare 'RepeatedStartMfaSignInRequest',
    as ArrayRef[StartMfaSignInRequest()];

coerce 'RepeatedStartMfaSignInRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest'->new($_) } @$_ ] };

declare 'MapStringStartMfaSignInRequest',
    as HashRef[StartMfaSignInRequest()];

declare 'StartMfaSignInResponse',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse'];

coerce 'StartMfaSignInResponse',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse'->new($_) };

declare 'RepeatedStartMfaSignInResponse',
    as ArrayRef[StartMfaSignInResponse()];

coerce 'RepeatedStartMfaSignInResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse'->new($_) } @$_ ] };

declare 'MapStringStartMfaSignInResponse',
    as HashRef[StartMfaSignInResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Identitytoolkit::V2::AuthenticationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
