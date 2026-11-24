package Google::Apps::Script::Type::Drive::DriveAddonManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DriveAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest'];

coerce 'DriveAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest'->new($_) };

declare 'RepeatedDriveAddOnManifest',
    as ArrayRef[DriveAddOnManifest()];

coerce 'RepeatedDriveAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringDriveAddOnManifest',
    as HashRef[DriveAddOnManifest()];

declare 'DriveExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveExtensionPoint'];

coerce 'DriveExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveExtensionPoint'->new($_) };

declare 'RepeatedDriveExtensionPoint',
    as ArrayRef[DriveExtensionPoint()];

coerce 'RepeatedDriveExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringDriveExtensionPoint',
    as HashRef[DriveExtensionPoint()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::Drive::DriveAddonManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
