package Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetSecuritySettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest'];

coerce 'GetSecuritySettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest'->new($_) };

declare 'RepeatedGetSecuritySettingsRequest',
    as ArrayRef[GetSecuritySettingsRequest()];

coerce 'RepeatedGetSecuritySettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecuritySettingsRequest',
    as HashRef[GetSecuritySettingsRequest()];

declare 'UpdateSecuritySettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::UpdateSecuritySettingsRequest'];

coerce 'UpdateSecuritySettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::UpdateSecuritySettingsRequest'->new($_) };

declare 'RepeatedUpdateSecuritySettingsRequest',
    as ArrayRef[UpdateSecuritySettingsRequest()];

coerce 'RepeatedUpdateSecuritySettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::UpdateSecuritySettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecuritySettingsRequest',
    as HashRef[UpdateSecuritySettingsRequest()];

declare 'ListSecuritySettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsRequest'];

coerce 'ListSecuritySettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsRequest'->new($_) };

declare 'RepeatedListSecuritySettingsRequest',
    as ArrayRef[ListSecuritySettingsRequest()];

coerce 'RepeatedListSecuritySettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsRequest'->new($_) } @$_ ] };

declare 'MapStringListSecuritySettingsRequest',
    as HashRef[ListSecuritySettingsRequest()];

declare 'ListSecuritySettingsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsResponse'];

coerce 'ListSecuritySettingsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsResponse'->new($_) };

declare 'RepeatedListSecuritySettingsResponse',
    as ArrayRef[ListSecuritySettingsResponse()];

coerce 'RepeatedListSecuritySettingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsResponse'->new($_) } @$_ ] };

declare 'MapStringListSecuritySettingsResponse',
    as HashRef[ListSecuritySettingsResponse()];

declare 'CreateSecuritySettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest'];

coerce 'CreateSecuritySettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest'->new($_) };

declare 'RepeatedCreateSecuritySettingsRequest',
    as ArrayRef[CreateSecuritySettingsRequest()];

coerce 'RepeatedCreateSecuritySettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecuritySettingsRequest',
    as HashRef[CreateSecuritySettingsRequest()];

declare 'DeleteSecuritySettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::DeleteSecuritySettingsRequest'];

coerce 'DeleteSecuritySettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::DeleteSecuritySettingsRequest'->new($_) };

declare 'RepeatedDeleteSecuritySettingsRequest',
    as ArrayRef[DeleteSecuritySettingsRequest()];

coerce 'RepeatedDeleteSecuritySettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::DeleteSecuritySettingsRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSecuritySettingsRequest',
    as HashRef[DeleteSecuritySettingsRequest()];

declare 'SecuritySettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings'];

coerce 'SecuritySettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings'->new($_) };

declare 'RepeatedSecuritySettings',
    as ArrayRef[SecuritySettings()];

coerce 'RepeatedSecuritySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings'->new($_) } @$_ ] };

declare 'MapStringSecuritySettings',
    as HashRef[SecuritySettings()];

declare 'RedactionStrategy',
    as (Int | Str);

declare 'RedactionScope',
    as (Int | Str);

declare 'RetentionStrategy',
    as (Int | Str);

declare 'PurgeDataType',
    as (Int | Str);

declare 'AudioExportSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::AudioExportSettings'];

coerce 'AudioExportSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::AudioExportSettings'->new($_) };

declare 'RepeatedAudioExportSettings',
    as ArrayRef[AudioExportSettings()];

coerce 'RepeatedAudioExportSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::AudioExportSettings'->new($_) } @$_ ] };

declare 'MapStringAudioExportSettings',
    as HashRef[AudioExportSettings()];

declare 'AudioFormat',
    as (Int | Str);

declare 'InsightsExportSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::InsightsExportSettings'];

coerce 'InsightsExportSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::InsightsExportSettings'->new($_) };

declare 'RepeatedInsightsExportSettings',
    as ArrayRef[InsightsExportSettings()];

coerce 'RepeatedInsightsExportSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::InsightsExportSettings'->new($_) } @$_ ] };

declare 'MapStringInsightsExportSettings',
    as HashRef[InsightsExportSettings()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
