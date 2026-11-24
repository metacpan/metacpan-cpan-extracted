package Google::Cloud::Databasecenter::V1beta::MachineConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MachineConfig',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig'];

coerce 'MachineConfig',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig'->new($_) };

declare 'RepeatedMachineConfig',
    as ArrayRef[MachineConfig()];

coerce 'RepeatedMachineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig'->new($_) } @$_ ] };

declare 'MapStringMachineConfig',
    as HashRef[MachineConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::MachineConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
