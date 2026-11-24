package Google::Apps::Script::Type::Sheets::SheetsAddonManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SheetsAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest'];

coerce 'SheetsAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest'->new($_) };

declare 'RepeatedSheetsAddOnManifest',
    as ArrayRef[SheetsAddOnManifest()];

coerce 'RepeatedSheetsAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringSheetsAddOnManifest',
    as HashRef[SheetsAddOnManifest()];

declare 'SheetsExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsExtensionPoint'];

coerce 'SheetsExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsExtensionPoint'->new($_) };

declare 'RepeatedSheetsExtensionPoint',
    as ArrayRef[SheetsExtensionPoint()];

coerce 'RepeatedSheetsExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringSheetsExtensionPoint',
    as HashRef[SheetsExtensionPoint()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::Sheets::SheetsAddonManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
