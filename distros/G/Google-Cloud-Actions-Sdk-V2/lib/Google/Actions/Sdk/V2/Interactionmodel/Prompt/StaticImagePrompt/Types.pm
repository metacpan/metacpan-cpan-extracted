package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticImagePrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt'];

coerce 'StaticImagePrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt'->new($_) };

declare 'RepeatedStaticImagePrompt',
    as ArrayRef[StaticImagePrompt()];

coerce 'RepeatedStaticImagePrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt'->new($_) } @$_ ] };

declare 'MapStringStaticImagePrompt',
    as HashRef[StaticImagePrompt()];

declare 'ImageFill',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
