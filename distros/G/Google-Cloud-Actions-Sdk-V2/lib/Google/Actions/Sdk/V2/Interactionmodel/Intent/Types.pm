package Google::Actions::Sdk::V2::Interactionmodel::Intent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Intent',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent'];

coerce 'Intent',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent'->new($_) };

declare 'RepeatedIntent',
    as ArrayRef[Intent()];

coerce 'RepeatedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent'->new($_) } @$_ ] };

declare 'MapStringIntent',
    as HashRef[Intent()];

declare 'IntentParameter',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter'];

coerce 'IntentParameter',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter'->new($_) };

declare 'RepeatedIntentParameter',
    as ArrayRef[IntentParameter()];

coerce 'RepeatedIntentParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter'->new($_) } @$_ ] };

declare 'MapStringIntentParameter',
    as HashRef[IntentParameter()];

declare 'EntitySetReferences',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter::EntitySetReferences'];

coerce 'EntitySetReferences',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter::EntitySetReferences'->new($_) };

declare 'RepeatedEntitySetReferences',
    as ArrayRef[EntitySetReferences()];

coerce 'RepeatedEntitySetReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter::EntitySetReferences'->new($_) } @$_ ] };

declare 'MapStringEntitySetReferences',
    as HashRef[EntitySetReferences()];

declare 'EntitySetReference',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter::EntitySetReferences::EntitySetReference'];

coerce 'EntitySetReference',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter::EntitySetReferences::EntitySetReference'->new($_) };

declare 'RepeatedEntitySetReference',
    as ArrayRef[EntitySetReference()];

coerce 'RepeatedEntitySetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter::EntitySetReferences::EntitySetReference'->new($_) } @$_ ] };

declare 'MapStringEntitySetReference',
    as HashRef[EntitySetReference()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Intent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
