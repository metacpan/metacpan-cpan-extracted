package Google::Cloud::Advisorynotifications::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NotificationView',
    as (Int | Str);

declare 'LocalizationState',
    as (Int | Str);

declare 'NotificationType',
    as (Int | Str);

declare 'Notification',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Notification'];

coerce 'Notification',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Notification'->new($_) };

declare 'RepeatedNotification',
    as ArrayRef[Notification()];

coerce 'RepeatedNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Notification'->new($_) } @$_ ] };

declare 'MapStringNotification',
    as HashRef[Notification()];

declare 'Text',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Text'];

coerce 'Text',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Text'->new($_) };

declare 'RepeatedText',
    as ArrayRef[Text()];

coerce 'RepeatedText',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Text'->new($_) } @$_ ] };

declare 'MapStringText',
    as HashRef[Text()];

declare 'Subject',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Subject'];

coerce 'Subject',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Subject'->new($_) };

declare 'RepeatedSubject',
    as ArrayRef[Subject()];

coerce 'RepeatedSubject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Subject'->new($_) } @$_ ] };

declare 'MapStringSubject',
    as HashRef[Subject()];

declare 'Message',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'Body',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Message::Body'];

coerce 'Body',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Message::Body'->new($_) };

declare 'RepeatedBody',
    as ArrayRef[Body()];

coerce 'RepeatedBody',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Message::Body'->new($_) } @$_ ] };

declare 'MapStringBody',
    as HashRef[Body()];

declare 'Attachment',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Attachment'];

coerce 'Attachment',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Attachment'->new($_) };

declare 'RepeatedAttachment',
    as ArrayRef[Attachment()];

coerce 'RepeatedAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Attachment'->new($_) } @$_ ] };

declare 'MapStringAttachment',
    as HashRef[Attachment()];

declare 'Csv',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Csv'];

coerce 'Csv',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Csv'->new($_) };

declare 'RepeatedCsv',
    as ArrayRef[Csv()];

coerce 'RepeatedCsv',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Csv'->new($_) } @$_ ] };

declare 'MapStringCsv',
    as HashRef[Csv()];

declare 'CsvRow',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Csv::CsvRow'];

coerce 'CsvRow',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Csv::CsvRow'->new($_) };

declare 'RepeatedCsvRow',
    as ArrayRef[CsvRow()];

coerce 'RepeatedCsvRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Csv::CsvRow'->new($_) } @$_ ] };

declare 'MapStringCsvRow',
    as HashRef[CsvRow()];

declare 'ListNotificationsRequest',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsRequest'];

coerce 'ListNotificationsRequest',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsRequest'->new($_) };

declare 'RepeatedListNotificationsRequest',
    as ArrayRef[ListNotificationsRequest()];

coerce 'RepeatedListNotificationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsRequest'->new($_) } @$_ ] };

declare 'MapStringListNotificationsRequest',
    as HashRef[ListNotificationsRequest()];

declare 'ListNotificationsResponse',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsResponse'];

coerce 'ListNotificationsResponse',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsResponse'->new($_) };

declare 'RepeatedListNotificationsResponse',
    as ArrayRef[ListNotificationsResponse()];

coerce 'RepeatedListNotificationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsResponse'->new($_) } @$_ ] };

declare 'MapStringListNotificationsResponse',
    as HashRef[ListNotificationsResponse()];

declare 'GetNotificationRequest',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::GetNotificationRequest'];

coerce 'GetNotificationRequest',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::GetNotificationRequest'->new($_) };

declare 'RepeatedGetNotificationRequest',
    as ArrayRef[GetNotificationRequest()];

coerce 'RepeatedGetNotificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::GetNotificationRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationRequest',
    as HashRef[GetNotificationRequest()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'NotificationSettingsEntry',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::Settings::NotificationSettingsEntry'];

coerce 'NotificationSettingsEntry',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::Settings::NotificationSettingsEntry'->new($_) };

declare 'RepeatedNotificationSettingsEntry',
    as ArrayRef[NotificationSettingsEntry()];

coerce 'RepeatedNotificationSettingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::Settings::NotificationSettingsEntry'->new($_) } @$_ ] };

declare 'MapStringNotificationSettingsEntry',
    as HashRef[NotificationSettingsEntry()];

declare 'NotificationSettings',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::NotificationSettings'];

coerce 'NotificationSettings',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::NotificationSettings'->new($_) };

declare 'RepeatedNotificationSettings',
    as ArrayRef[NotificationSettings()];

coerce 'RepeatedNotificationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::NotificationSettings'->new($_) } @$_ ] };

declare 'MapStringNotificationSettings',
    as HashRef[NotificationSettings()];

declare 'GetSettingsRequest',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::GetSettingsRequest'];

coerce 'GetSettingsRequest',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::GetSettingsRequest'->new($_) };

declare 'RepeatedGetSettingsRequest',
    as ArrayRef[GetSettingsRequest()];

coerce 'RepeatedGetSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::GetSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSettingsRequest',
    as HashRef[GetSettingsRequest()];

declare 'UpdateSettingsRequest',
    as InstanceOf['Google::Cloud::Advisorynotifications::V1::Service::UpdateSettingsRequest'];

coerce 'UpdateSettingsRequest',
    from HashRef, via { 'Google::Cloud::Advisorynotifications::V1::Service::UpdateSettingsRequest'->new($_) };

declare 'RepeatedUpdateSettingsRequest',
    as ArrayRef[UpdateSettingsRequest()];

coerce 'RepeatedUpdateSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Advisorynotifications::V1::Service::UpdateSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSettingsRequest',
    as HashRef[UpdateSettingsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Advisorynotifications::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
