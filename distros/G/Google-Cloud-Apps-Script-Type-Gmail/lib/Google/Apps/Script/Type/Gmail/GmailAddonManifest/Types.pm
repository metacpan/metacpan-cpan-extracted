package Google::Apps::Script::Type::Gmail::GmailAddonManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GmailAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest'];

coerce 'GmailAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest'->new($_) };

declare 'RepeatedGmailAddOnManifest',
    as ArrayRef[GmailAddOnManifest()];

coerce 'RepeatedGmailAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringGmailAddOnManifest',
    as HashRef[GmailAddOnManifest()];

declare 'UniversalAction',
    as InstanceOf['Google::Apps::Script::Type::Gmail::GmailAddonManifest::UniversalAction'];

coerce 'UniversalAction',
    from HashRef, via { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::UniversalAction'->new($_) };

declare 'RepeatedUniversalAction',
    as ArrayRef[UniversalAction()];

coerce 'RepeatedUniversalAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::UniversalAction'->new($_) } @$_ ] };

declare 'MapStringUniversalAction',
    as HashRef[UniversalAction()];

declare 'ComposeTrigger',
    as InstanceOf['Google::Apps::Script::Type::Gmail::GmailAddonManifest::ComposeTrigger'];

coerce 'ComposeTrigger',
    from HashRef, via { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::ComposeTrigger'->new($_) };

declare 'RepeatedComposeTrigger',
    as ArrayRef[ComposeTrigger()];

coerce 'RepeatedComposeTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::ComposeTrigger'->new($_) } @$_ ] };

declare 'MapStringComposeTrigger',
    as HashRef[ComposeTrigger()];

declare 'DraftAccess',
    as (Int | Str);

declare 'ContextualTrigger',
    as InstanceOf['Google::Apps::Script::Type::Gmail::GmailAddonManifest::ContextualTrigger'];

coerce 'ContextualTrigger',
    from HashRef, via { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::ContextualTrigger'->new($_) };

declare 'RepeatedContextualTrigger',
    as ArrayRef[ContextualTrigger()];

coerce 'RepeatedContextualTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::ContextualTrigger'->new($_) } @$_ ] };

declare 'MapStringContextualTrigger',
    as HashRef[ContextualTrigger()];

declare 'UnconditionalTrigger',
    as InstanceOf['Google::Apps::Script::Type::Gmail::GmailAddonManifest::UnconditionalTrigger'];

coerce 'UnconditionalTrigger',
    from HashRef, via { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::UnconditionalTrigger'->new($_) };

declare 'RepeatedUnconditionalTrigger',
    as ArrayRef[UnconditionalTrigger()];

coerce 'RepeatedUnconditionalTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Gmail::GmailAddonManifest::UnconditionalTrigger'->new($_) } @$_ ] };

declare 'MapStringUnconditionalTrigger',
    as HashRef[UnconditionalTrigger()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::Gmail::GmailAddonManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
