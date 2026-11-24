package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticCollectionBrowsePrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt'];

coerce 'StaticCollectionBrowsePrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt'->new($_) };

declare 'RepeatedStaticCollectionBrowsePrompt',
    as ArrayRef[StaticCollectionBrowsePrompt()];

coerce 'RepeatedStaticCollectionBrowsePrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt'->new($_) } @$_ ] };

declare 'MapStringStaticCollectionBrowsePrompt',
    as HashRef[StaticCollectionBrowsePrompt()];

declare 'CollectionBrowseItem',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt::CollectionBrowseItem'];

coerce 'CollectionBrowseItem',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt::CollectionBrowseItem'->new($_) };

declare 'RepeatedCollectionBrowseItem',
    as ArrayRef[CollectionBrowseItem()];

coerce 'RepeatedCollectionBrowseItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt::CollectionBrowseItem'->new($_) } @$_ ] };

declare 'MapStringCollectionBrowseItem',
    as HashRef[CollectionBrowseItem()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
