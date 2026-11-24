package Google::Actions::Sdk::V2::Interactionmodel::Scene::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Scene',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene'];

coerce 'Scene',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene'->new($_) };

declare 'RepeatedScene',
    as ArrayRef[Scene()];

coerce 'RepeatedScene',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene'->new($_) } @$_ ] };

declare 'MapStringScene',
    as HashRef[Scene()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Scene::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
