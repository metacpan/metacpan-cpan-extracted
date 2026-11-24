package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticMediaPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt'];

coerce 'StaticMediaPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt'->new($_) };

declare 'RepeatedStaticMediaPrompt',
    as ArrayRef[StaticMediaPrompt()];

coerce 'RepeatedStaticMediaPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticMediaPrompt',
    as HashRef[StaticMediaPrompt()];

declare 'MediaType',
    as (Int | Str);

declare 'OptionalMediaControls',
    as (Int | Str);

declare 'RepeatMode',
    as (Int | Str);

declare 'MediaObject',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaObject'];

coerce 'MediaObject',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaObject'->new($_) };

declare 'RepeatedMediaObject',
    as ArrayRef[MediaObject()];

coerce 'RepeatedMediaObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaObject'->new($_) } @$_ ] };

declare 'MapStringMediaObject',
    as HashRef[MediaObject()];

declare 'MediaImage',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaImage'];

coerce 'MediaImage',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaImage'->new($_) };

declare 'RepeatedMediaImage',
    as ArrayRef[MediaImage()];

coerce 'RepeatedMediaImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaImage'->new($_) } @$_ ] };

declare 'MapStringMediaImage',
    as HashRef[MediaImage()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
