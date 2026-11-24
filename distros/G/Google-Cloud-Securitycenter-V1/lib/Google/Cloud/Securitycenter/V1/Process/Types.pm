package Google::Cloud::Securitycenter::V1::Process::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Process',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Process::Process'];

coerce 'Process',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Process::Process'->new($_) };

declare 'RepeatedProcess',
    as ArrayRef[Process()];

coerce 'RepeatedProcess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Process::Process'->new($_) } @$_ ] };

declare 'MapStringProcess',
    as HashRef[Process()];

declare 'EnvironmentVariable',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Process::EnvironmentVariable'];

coerce 'EnvironmentVariable',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Process::EnvironmentVariable'->new($_) };

declare 'RepeatedEnvironmentVariable',
    as ArrayRef[EnvironmentVariable()];

coerce 'RepeatedEnvironmentVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Process::EnvironmentVariable'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariable',
    as HashRef[EnvironmentVariable()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Process::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
