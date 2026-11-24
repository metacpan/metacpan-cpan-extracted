package Google::Apps::Script::Type::ExtensionPoint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MenuItemExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint'];

coerce 'MenuItemExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint'->new($_) };

declare 'RepeatedMenuItemExtensionPoint',
    as ArrayRef[MenuItemExtensionPoint()];

coerce 'RepeatedMenuItemExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringMenuItemExtensionPoint',
    as HashRef[MenuItemExtensionPoint()];

declare 'HomepageExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint'];

coerce 'HomepageExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint'->new($_) };

declare 'RepeatedHomepageExtensionPoint',
    as ArrayRef[HomepageExtensionPoint()];

coerce 'RepeatedHomepageExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringHomepageExtensionPoint',
    as HashRef[HomepageExtensionPoint()];

declare 'UniversalActionExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::ExtensionPoint::UniversalActionExtensionPoint'];

coerce 'UniversalActionExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::ExtensionPoint::UniversalActionExtensionPoint'->new($_) };

declare 'RepeatedUniversalActionExtensionPoint',
    as ArrayRef[UniversalActionExtensionPoint()];

coerce 'RepeatedUniversalActionExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::ExtensionPoint::UniversalActionExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringUniversalActionExtensionPoint',
    as HashRef[UniversalActionExtensionPoint()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::ExtensionPoint::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
