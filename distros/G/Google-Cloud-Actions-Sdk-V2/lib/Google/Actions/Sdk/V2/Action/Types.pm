package Google::Actions::Sdk::V2::Action::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Actions',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions'];

coerce 'Actions',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions'->new($_) };

declare 'RepeatedActions',
    as ArrayRef[Actions()];

coerce 'RepeatedActions',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions'->new($_) } @$_ ] };

declare 'MapStringActions',
    as HashRef[Actions()];

declare 'Engagement',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::Engagement'];

coerce 'Engagement',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::Engagement'->new($_) };

declare 'RepeatedEngagement',
    as ArrayRef[Engagement()];

coerce 'RepeatedEngagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::Engagement'->new($_) } @$_ ] };

declare 'MapStringEngagement',
    as HashRef[Engagement()];

declare 'PushNotification',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::Engagement::PushNotification'];

coerce 'PushNotification',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::PushNotification'->new($_) };

declare 'RepeatedPushNotification',
    as ArrayRef[PushNotification()];

coerce 'RepeatedPushNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::PushNotification'->new($_) } @$_ ] };

declare 'MapStringPushNotification',
    as HashRef[PushNotification()];

declare 'DailyUpdate',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::Engagement::DailyUpdate'];

coerce 'DailyUpdate',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::DailyUpdate'->new($_) };

declare 'RepeatedDailyUpdate',
    as ArrayRef[DailyUpdate()];

coerce 'RepeatedDailyUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::DailyUpdate'->new($_) } @$_ ] };

declare 'MapStringDailyUpdate',
    as HashRef[DailyUpdate()];

declare 'ActionLink',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::Engagement::ActionLink'];

coerce 'ActionLink',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::ActionLink'->new($_) };

declare 'RepeatedActionLink',
    as ArrayRef[ActionLink()];

coerce 'RepeatedActionLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::ActionLink'->new($_) } @$_ ] };

declare 'MapStringActionLink',
    as HashRef[ActionLink()];

declare 'AssistantLink',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::Engagement::AssistantLink'];

coerce 'AssistantLink',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::AssistantLink'->new($_) };

declare 'RepeatedAssistantLink',
    as ArrayRef[AssistantLink()];

coerce 'RepeatedAssistantLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::Engagement::AssistantLink'->new($_) } @$_ ] };

declare 'MapStringAssistantLink',
    as HashRef[AssistantLink()];

declare 'CustomAction',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::CustomAction'];

coerce 'CustomAction',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::CustomAction'->new($_) };

declare 'RepeatedCustomAction',
    as ArrayRef[CustomAction()];

coerce 'RepeatedCustomAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::CustomAction'->new($_) } @$_ ] };

declare 'MapStringCustomAction',
    as HashRef[CustomAction()];

declare 'CustomEntry',
    as InstanceOf['Google::Actions::Sdk::V2::Action::Actions::CustomEntry'];

coerce 'CustomEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::Action::Actions::CustomEntry'->new($_) };

declare 'RepeatedCustomEntry',
    as ArrayRef[CustomEntry()];

coerce 'RepeatedCustomEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Action::Actions::CustomEntry'->new($_) } @$_ ] };

declare 'MapStringCustomEntry',
    as HashRef[CustomEntry()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Action::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
