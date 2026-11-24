package Google::Cloud::Securitycenter::V1::Simulation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Simulation',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Simulation::Simulation'];

coerce 'Simulation',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Simulation::Simulation'->new($_) };

declare 'RepeatedSimulation',
    as ArrayRef[Simulation()];

coerce 'RepeatedSimulation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Simulation::Simulation'->new($_) } @$_ ] };

declare 'MapStringSimulation',
    as HashRef[Simulation()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Simulation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
