package Google::Cloud::Discoveryengine::V1::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ObservabilityConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig'];

coerce 'ObservabilityConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig'->new($_) };

declare 'RepeatedObservabilityConfig',
    as ArrayRef[ObservabilityConfig()];

coerce 'RepeatedObservabilityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig'->new($_) } @$_ ] };

declare 'MapStringObservabilityConfig',
    as HashRef[ObservabilityConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
