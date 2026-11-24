package Google::Monitoring::V3::NotificationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListNotificationChannelDescriptorsRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest'];

coerce 'ListNotificationChannelDescriptorsRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest'->new($_) };

declare 'RepeatedListNotificationChannelDescriptorsRequest',
    as ArrayRef[ListNotificationChannelDescriptorsRequest()];

coerce 'RepeatedListNotificationChannelDescriptorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest'->new($_) } @$_ ] };

declare 'MapStringListNotificationChannelDescriptorsRequest',
    as HashRef[ListNotificationChannelDescriptorsRequest()];

declare 'ListNotificationChannelDescriptorsResponse',
    as InstanceOf['Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse'];

coerce 'ListNotificationChannelDescriptorsResponse',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse'->new($_) };

declare 'RepeatedListNotificationChannelDescriptorsResponse',
    as ArrayRef[ListNotificationChannelDescriptorsResponse()];

coerce 'RepeatedListNotificationChannelDescriptorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse'->new($_) } @$_ ] };

declare 'MapStringListNotificationChannelDescriptorsResponse',
    as HashRef[ListNotificationChannelDescriptorsResponse()];

declare 'GetNotificationChannelDescriptorRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::GetNotificationChannelDescriptorRequest'];

coerce 'GetNotificationChannelDescriptorRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelDescriptorRequest'->new($_) };

declare 'RepeatedGetNotificationChannelDescriptorRequest',
    as ArrayRef[GetNotificationChannelDescriptorRequest()];

coerce 'RepeatedGetNotificationChannelDescriptorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelDescriptorRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationChannelDescriptorRequest',
    as HashRef[GetNotificationChannelDescriptorRequest()];

declare 'CreateNotificationChannelRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::CreateNotificationChannelRequest'];

coerce 'CreateNotificationChannelRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::CreateNotificationChannelRequest'->new($_) };

declare 'RepeatedCreateNotificationChannelRequest',
    as ArrayRef[CreateNotificationChannelRequest()];

coerce 'RepeatedCreateNotificationChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::CreateNotificationChannelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNotificationChannelRequest',
    as HashRef[CreateNotificationChannelRequest()];

declare 'ListNotificationChannelsRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::ListNotificationChannelsRequest'];

coerce 'ListNotificationChannelsRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelsRequest'->new($_) };

declare 'RepeatedListNotificationChannelsRequest',
    as ArrayRef[ListNotificationChannelsRequest()];

coerce 'RepeatedListNotificationChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListNotificationChannelsRequest',
    as HashRef[ListNotificationChannelsRequest()];

declare 'ListNotificationChannelsResponse',
    as InstanceOf['Google::Monitoring::V3::NotificationService::ListNotificationChannelsResponse'];

coerce 'ListNotificationChannelsResponse',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelsResponse'->new($_) };

declare 'RepeatedListNotificationChannelsResponse',
    as ArrayRef[ListNotificationChannelsResponse()];

coerce 'RepeatedListNotificationChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::ListNotificationChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListNotificationChannelsResponse',
    as HashRef[ListNotificationChannelsResponse()];

declare 'GetNotificationChannelRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::GetNotificationChannelRequest'];

coerce 'GetNotificationChannelRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelRequest'->new($_) };

declare 'RepeatedGetNotificationChannelRequest',
    as ArrayRef[GetNotificationChannelRequest()];

coerce 'RepeatedGetNotificationChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationChannelRequest',
    as HashRef[GetNotificationChannelRequest()];

declare 'UpdateNotificationChannelRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::UpdateNotificationChannelRequest'];

coerce 'UpdateNotificationChannelRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::UpdateNotificationChannelRequest'->new($_) };

declare 'RepeatedUpdateNotificationChannelRequest',
    as ArrayRef[UpdateNotificationChannelRequest()];

coerce 'RepeatedUpdateNotificationChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::UpdateNotificationChannelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNotificationChannelRequest',
    as HashRef[UpdateNotificationChannelRequest()];

declare 'DeleteNotificationChannelRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::DeleteNotificationChannelRequest'];

coerce 'DeleteNotificationChannelRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::DeleteNotificationChannelRequest'->new($_) };

declare 'RepeatedDeleteNotificationChannelRequest',
    as ArrayRef[DeleteNotificationChannelRequest()];

coerce 'RepeatedDeleteNotificationChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::DeleteNotificationChannelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNotificationChannelRequest',
    as HashRef[DeleteNotificationChannelRequest()];

declare 'SendNotificationChannelVerificationCodeRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::SendNotificationChannelVerificationCodeRequest'];

coerce 'SendNotificationChannelVerificationCodeRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::SendNotificationChannelVerificationCodeRequest'->new($_) };

declare 'RepeatedSendNotificationChannelVerificationCodeRequest',
    as ArrayRef[SendNotificationChannelVerificationCodeRequest()];

coerce 'RepeatedSendNotificationChannelVerificationCodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::SendNotificationChannelVerificationCodeRequest'->new($_) } @$_ ] };

declare 'MapStringSendNotificationChannelVerificationCodeRequest',
    as HashRef[SendNotificationChannelVerificationCodeRequest()];

declare 'GetNotificationChannelVerificationCodeRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeRequest'];

coerce 'GetNotificationChannelVerificationCodeRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeRequest'->new($_) };

declare 'RepeatedGetNotificationChannelVerificationCodeRequest',
    as ArrayRef[GetNotificationChannelVerificationCodeRequest()];

coerce 'RepeatedGetNotificationChannelVerificationCodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationChannelVerificationCodeRequest',
    as HashRef[GetNotificationChannelVerificationCodeRequest()];

declare 'GetNotificationChannelVerificationCodeResponse',
    as InstanceOf['Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeResponse'];

coerce 'GetNotificationChannelVerificationCodeResponse',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeResponse'->new($_) };

declare 'RepeatedGetNotificationChannelVerificationCodeResponse',
    as ArrayRef[GetNotificationChannelVerificationCodeResponse()];

coerce 'RepeatedGetNotificationChannelVerificationCodeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeResponse'->new($_) } @$_ ] };

declare 'MapStringGetNotificationChannelVerificationCodeResponse',
    as HashRef[GetNotificationChannelVerificationCodeResponse()];

declare 'VerifyNotificationChannelRequest',
    as InstanceOf['Google::Monitoring::V3::NotificationService::VerifyNotificationChannelRequest'];

coerce 'VerifyNotificationChannelRequest',
    from HashRef, via { 'Google::Monitoring::V3::NotificationService::VerifyNotificationChannelRequest'->new($_) };

declare 'RepeatedVerifyNotificationChannelRequest',
    as ArrayRef[VerifyNotificationChannelRequest()];

coerce 'RepeatedVerifyNotificationChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::NotificationService::VerifyNotificationChannelRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyNotificationChannelRequest',
    as HashRef[VerifyNotificationChannelRequest()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::NotificationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
