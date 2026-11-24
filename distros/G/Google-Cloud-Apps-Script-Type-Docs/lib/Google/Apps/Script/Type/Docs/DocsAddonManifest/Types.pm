package Google::Apps::Script::Type::Docs::DocsAddonManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocsAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest'];

coerce 'DocsAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest'->new($_) };

declare 'RepeatedDocsAddOnManifest',
    as ArrayRef[DocsAddOnManifest()];

coerce 'RepeatedDocsAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringDocsAddOnManifest',
    as HashRef[DocsAddOnManifest()];

declare 'DocsExtensionPoint',
    as InstanceOf['Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsExtensionPoint'];

coerce 'DocsExtensionPoint',
    from HashRef, via { 'Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsExtensionPoint'->new($_) };

declare 'RepeatedDocsExtensionPoint',
    as ArrayRef[DocsExtensionPoint()];

coerce 'RepeatedDocsExtensionPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsExtensionPoint'->new($_) } @$_ ] };

declare 'MapStringDocsExtensionPoint',
    as HashRef[DocsExtensionPoint()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::Docs::DocsAddonManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
