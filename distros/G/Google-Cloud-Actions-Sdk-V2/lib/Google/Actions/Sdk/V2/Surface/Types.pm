package Google::Actions::Sdk::V2::Surface::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SurfaceRequirements',
    as InstanceOf['Google::Actions::Sdk::V2::Surface::SurfaceRequirements'];

coerce 'SurfaceRequirements',
    from HashRef, via { 'Google::Actions::Sdk::V2::Surface::SurfaceRequirements'->new($_) };

declare 'RepeatedSurfaceRequirements',
    as ArrayRef[SurfaceRequirements()];

coerce 'RepeatedSurfaceRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Surface::SurfaceRequirements'->new($_) } @$_ ] };

declare 'MapStringSurfaceRequirements',
    as HashRef[SurfaceRequirements()];

declare 'CapabilityRequirement',
    as InstanceOf['Google::Actions::Sdk::V2::Surface::CapabilityRequirement'];

coerce 'CapabilityRequirement',
    from HashRef, via { 'Google::Actions::Sdk::V2::Surface::CapabilityRequirement'->new($_) };

declare 'RepeatedCapabilityRequirement',
    as ArrayRef[CapabilityRequirement()];

coerce 'RepeatedCapabilityRequirement',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Surface::CapabilityRequirement'->new($_) } @$_ ] };

declare 'MapStringCapabilityRequirement',
    as HashRef[CapabilityRequirement()];

declare 'SurfaceCapability',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Surface::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
