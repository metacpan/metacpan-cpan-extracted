package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticSimplePrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt'];

coerce 'StaticSimplePrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt'->new($_) };

declare 'RepeatedStaticSimplePrompt',
    as ArrayRef[StaticSimplePrompt()];

coerce 'RepeatedStaticSimplePrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt'->new($_) } @$_ ] };

declare 'MapStringStaticSimplePrompt',
    as HashRef[StaticSimplePrompt()];

declare 'Variant',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt::Variant'];

coerce 'Variant',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt::Variant'->new($_) };

declare 'RepeatedVariant',
    as ArrayRef[Variant()];

coerce 'RepeatedVariant',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt::Variant'->new($_) } @$_ ] };

declare 'MapStringVariant',
    as HashRef[Variant()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
