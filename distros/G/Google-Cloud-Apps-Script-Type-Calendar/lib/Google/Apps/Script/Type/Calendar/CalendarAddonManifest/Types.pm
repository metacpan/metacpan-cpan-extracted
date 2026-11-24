package Google::Apps::Script::Type::Calendar::CalendarAddonManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CalendarAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest'];

coerce 'CalendarAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest'->new($_) };

declare 'RepeatedCalendarAddOnManifest',
    as ArrayRef[CalendarAddOnManifest()];

coerce 'RepeatedCalendarAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringCalendarAddOnManifest',
    as HashRef[CalendarAddOnManifest()];

declare 'EventAccess',
    as (Int | Str);

declare 'ConferenceSolution',
    as InstanceOf['Google::Apps::Script::Type::Calendar::CalendarAddonManifest::ConferenceSolution'];

coerce 'ConferenceSolution',
    from HashRef, via { 'Google::Apps::Script::Type::Calendar::CalendarAddonManifest::ConferenceSolution'->new($_) };

declare 'RepeatedConferenceSolution',
    as ArrayRef[ConferenceSolution()];

coerce 'RepeatedConferenceSolution',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Calendar::CalendarAddonManifest::ConferenceSolution'->new($_) } @$_ ] };

declare 'MapStringConferenceSolution',
    as HashRef[ConferenceSolution()];

declare 'CalendarExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint'];

coerce 'CalendarExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint'->new($_) };

declare 'RepeatedCalendarExtensionPoint',
    as ArrayRef[CalendarExtensionPoint()];

coerce 'RepeatedCalendarExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringCalendarExtensionPoint',
    as HashRef[CalendarExtensionPoint()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::Calendar::CalendarAddonManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
