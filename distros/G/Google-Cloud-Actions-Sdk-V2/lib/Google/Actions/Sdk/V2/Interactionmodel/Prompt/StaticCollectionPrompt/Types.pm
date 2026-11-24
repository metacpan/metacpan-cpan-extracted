package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticCollectionPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt'];

coerce 'StaticCollectionPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt'->new($_) };

declare 'RepeatedStaticCollectionPrompt',
    as ArrayRef[StaticCollectionPrompt()];

coerce 'RepeatedStaticCollectionPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticCollectionPrompt',
    as HashRef[StaticCollectionPrompt()];

declare 'CollectionItem',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt::CollectionItem'];

coerce 'CollectionItem',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt::CollectionItem'->new($_) };

declare 'RepeatedCollectionItem',
    as ArrayRef[CollectionItem()];

coerce 'RepeatedCollectionItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt::CollectionItem'->new($_) } @$_ ] };

declare 'MapStringCollectionItem',
    as HashRef[CollectionItem()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
