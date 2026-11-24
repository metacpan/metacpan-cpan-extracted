package Google::Devicesandservices::Health::V4::HealthProfile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'User',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::User'];

coerce 'User',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'Profile',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::Profile'];

coerce 'Profile',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::Profile'->new($_) };

declare 'RepeatedProfile',
    as ArrayRef[Profile()];

coerce 'RepeatedProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::Profile'->new($_) } @$_ ] };

declare 'MapStringProfile',
    as HashRef[Profile()];

declare 'PairedDevice',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::PairedDevice'];

coerce 'PairedDevice',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::PairedDevice'->new($_) };

declare 'RepeatedPairedDevice',
    as ArrayRef[PairedDevice()];

coerce 'RepeatedPairedDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::PairedDevice'->new($_) } @$_ ] };

declare 'MapStringPairedDevice',
    as HashRef[PairedDevice()];

declare 'DeviceType',
    as (Int | Str);

declare 'IrnProfile',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::IrnProfile'];

coerce 'IrnProfile',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::IrnProfile'->new($_) };

declare 'RepeatedIrnProfile',
    as ArrayRef[IrnProfile()];

coerce 'RepeatedIrnProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::IrnProfile'->new($_) } @$_ ] };

declare 'MapStringIrnProfile',
    as HashRef[IrnProfile()];

declare 'Settings',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'DistanceUnit',
    as (Int | Str);

declare 'GlucoseUnit',
    as (Int | Str);

declare 'HeightUnit',
    as (Int | Str);

declare 'StrideLengthType',
    as (Int | Str);

declare 'SwimUnit',
    as (Int | Str);

declare 'TemperatureUnit',
    as (Int | Str);

declare 'WeightUnit',
    as (Int | Str);

declare 'WaterUnit',
    as (Int | Str);

declare 'Identity',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::Identity'];

coerce 'Identity',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::Identity'->new($_) };

declare 'RepeatedIdentity',
    as ArrayRef[Identity()];

coerce 'RepeatedIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::Identity'->new($_) } @$_ ] };

declare 'MapStringIdentity',
    as HashRef[Identity()];

declare 'GetProfileRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::GetProfileRequest'];

coerce 'GetProfileRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::GetProfileRequest'->new($_) };

declare 'RepeatedGetProfileRequest',
    as ArrayRef[GetProfileRequest()];

coerce 'RepeatedGetProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::GetProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetProfileRequest',
    as HashRef[GetProfileRequest()];

declare 'GetIrnProfileRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::GetIrnProfileRequest'];

coerce 'GetIrnProfileRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::GetIrnProfileRequest'->new($_) };

declare 'RepeatedGetIrnProfileRequest',
    as ArrayRef[GetIrnProfileRequest()];

coerce 'RepeatedGetIrnProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::GetIrnProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetIrnProfileRequest',
    as HashRef[GetIrnProfileRequest()];

declare 'UpdateProfileRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::UpdateProfileRequest'];

coerce 'UpdateProfileRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::UpdateProfileRequest'->new($_) };

declare 'RepeatedUpdateProfileRequest',
    as ArrayRef[UpdateProfileRequest()];

coerce 'RepeatedUpdateProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::UpdateProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProfileRequest',
    as HashRef[UpdateProfileRequest()];

declare 'GetSettingsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::GetSettingsRequest'];

coerce 'GetSettingsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::GetSettingsRequest'->new($_) };

declare 'RepeatedGetSettingsRequest',
    as ArrayRef[GetSettingsRequest()];

coerce 'RepeatedGetSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::GetSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSettingsRequest',
    as HashRef[GetSettingsRequest()];

declare 'UpdateSettingsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::UpdateSettingsRequest'];

coerce 'UpdateSettingsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::UpdateSettingsRequest'->new($_) };

declare 'RepeatedUpdateSettingsRequest',
    as ArrayRef[UpdateSettingsRequest()];

coerce 'RepeatedUpdateSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::UpdateSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSettingsRequest',
    as HashRef[UpdateSettingsRequest()];

declare 'GetIdentityRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::GetIdentityRequest'];

coerce 'GetIdentityRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::GetIdentityRequest'->new($_) };

declare 'RepeatedGetIdentityRequest',
    as ArrayRef[GetIdentityRequest()];

coerce 'RepeatedGetIdentityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::GetIdentityRequest'->new($_) } @$_ ] };

declare 'MapStringGetIdentityRequest',
    as HashRef[GetIdentityRequest()];

declare 'GetPairedDeviceRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::GetPairedDeviceRequest'];

coerce 'GetPairedDeviceRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::GetPairedDeviceRequest'->new($_) };

declare 'RepeatedGetPairedDeviceRequest',
    as ArrayRef[GetPairedDeviceRequest()];

coerce 'RepeatedGetPairedDeviceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::GetPairedDeviceRequest'->new($_) } @$_ ] };

declare 'MapStringGetPairedDeviceRequest',
    as HashRef[GetPairedDeviceRequest()];

declare 'ListPairedDevicesRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesRequest'];

coerce 'ListPairedDevicesRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesRequest'->new($_) };

declare 'RepeatedListPairedDevicesRequest',
    as ArrayRef[ListPairedDevicesRequest()];

coerce 'RepeatedListPairedDevicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesRequest'->new($_) } @$_ ] };

declare 'MapStringListPairedDevicesRequest',
    as HashRef[ListPairedDevicesRequest()];

declare 'ListPairedDevicesResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesResponse'];

coerce 'ListPairedDevicesResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesResponse'->new($_) };

declare 'RepeatedListPairedDevicesResponse',
    as ArrayRef[ListPairedDevicesResponse()];

coerce 'RepeatedListPairedDevicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::HealthProfile::ListPairedDevicesResponse'->new($_) } @$_ ] };

declare 'MapStringListPairedDevicesResponse',
    as HashRef[ListPairedDevicesResponse()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::HealthProfile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
