package Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SurfaceCapabilities',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities'];

coerce 'SurfaceCapabilities',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities'->new($_) };

declare 'RepeatedSurfaceCapabilities',
    as ArrayRef[SurfaceCapabilities()];

coerce 'RepeatedSurfaceCapabilities',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities'->new($_) } @$_ ] };

declare 'MapStringSurfaceCapabilities',
    as HashRef[SurfaceCapabilities()];

declare 'Capability',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
