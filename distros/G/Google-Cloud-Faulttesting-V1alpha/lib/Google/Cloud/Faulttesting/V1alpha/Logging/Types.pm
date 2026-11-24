package Google::Cloud::Faulttesting::V1alpha::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FaultTestingLog',
    as InstanceOf['Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog'];

coerce 'FaultTestingLog',
    from HashRef, via { 'Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog'->new($_) };

declare 'RepeatedFaultTestingLog',
    as ArrayRef[FaultTestingLog()];

coerce 'RepeatedFaultTestingLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog'->new($_) } @$_ ] };

declare 'MapStringFaultTestingLog',
    as HashRef[FaultTestingLog()];

1;

__END__

=head1 NAME

Google::Cloud::Faulttesting::V1alpha::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
