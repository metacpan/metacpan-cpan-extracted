package Google::Apps::Script::Type::Slides::SlidesAddonManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SlidesAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::Slides::SlidesAddonManifest::SlidesAddOnManifest'];

coerce 'SlidesAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::Slides::SlidesAddonManifest::SlidesAddOnManifest'->new($_) };

declare 'RepeatedSlidesAddOnManifest',
    as ArrayRef[SlidesAddOnManifest()];

coerce 'RepeatedSlidesAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Slides::SlidesAddonManifest::SlidesAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringSlidesAddOnManifest',
    as HashRef[SlidesAddOnManifest()];

declare 'SlidesExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::Slides::SlidesAddonManifest::SlidesExtensionPoint'];

coerce 'SlidesExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::Slides::SlidesAddonManifest::SlidesExtensionPoint'->new($_) };

declare 'RepeatedSlidesExtensionPoint',
    as ArrayRef[SlidesExtensionPoint()];

coerce 'RepeatedSlidesExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Slides::SlidesAddonManifest::SlidesExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringSlidesExtensionPoint',
    as HashRef[SlidesExtensionPoint()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::Slides::SlidesAddonManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
