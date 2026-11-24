package Google::Cloud::Apihub::V1::HostProjectRegistrationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateHostProjectRegistrationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest'];

coerce 'CreateHostProjectRegistrationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest'->new($_) };

declare 'RepeatedCreateHostProjectRegistrationRequest',
    as ArrayRef[CreateHostProjectRegistrationRequest()];

coerce 'RepeatedCreateHostProjectRegistrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHostProjectRegistrationRequest',
    as HashRef[CreateHostProjectRegistrationRequest()];

declare 'GetHostProjectRegistrationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::HostProjectRegistrationService::GetHostProjectRegistrationRequest'];

coerce 'GetHostProjectRegistrationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::GetHostProjectRegistrationRequest'->new($_) };

declare 'RepeatedGetHostProjectRegistrationRequest',
    as ArrayRef[GetHostProjectRegistrationRequest()];

coerce 'RepeatedGetHostProjectRegistrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::GetHostProjectRegistrationRequest'->new($_) } @$_ ] };

declare 'MapStringGetHostProjectRegistrationRequest',
    as HashRef[GetHostProjectRegistrationRequest()];

declare 'ListHostProjectRegistrationsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsRequest'];

coerce 'ListHostProjectRegistrationsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsRequest'->new($_) };

declare 'RepeatedListHostProjectRegistrationsRequest',
    as ArrayRef[ListHostProjectRegistrationsRequest()];

coerce 'RepeatedListHostProjectRegistrationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsRequest'->new($_) } @$_ ] };

declare 'MapStringListHostProjectRegistrationsRequest',
    as HashRef[ListHostProjectRegistrationsRequest()];

declare 'ListHostProjectRegistrationsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsResponse'];

coerce 'ListHostProjectRegistrationsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsResponse'->new($_) };

declare 'RepeatedListHostProjectRegistrationsResponse',
    as ArrayRef[ListHostProjectRegistrationsResponse()];

coerce 'RepeatedListHostProjectRegistrationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsResponse'->new($_) } @$_ ] };

declare 'MapStringListHostProjectRegistrationsResponse',
    as HashRef[ListHostProjectRegistrationsResponse()];

declare 'HostProjectRegistration',
    as InstanceOf['Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration'];

coerce 'HostProjectRegistration',
    from HashRef, via { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration'->new($_) };

declare 'RepeatedHostProjectRegistration',
    as ArrayRef[HostProjectRegistration()];

coerce 'RepeatedHostProjectRegistration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration'->new($_) } @$_ ] };

declare 'MapStringHostProjectRegistration',
    as HashRef[HostProjectRegistration()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::HostProjectRegistrationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
