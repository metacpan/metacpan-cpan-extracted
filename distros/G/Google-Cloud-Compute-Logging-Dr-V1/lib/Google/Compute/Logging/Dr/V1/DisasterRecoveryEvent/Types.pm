package Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DisasterRecoveryEvent',
    as InstanceOf['Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent'];

coerce 'DisasterRecoveryEvent',
    from HashRef, via { 'Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent'->new($_) };

declare 'RepeatedDisasterRecoveryEvent',
    as ArrayRef[DisasterRecoveryEvent()];

coerce 'RepeatedDisasterRecoveryEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent'->new($_) } @$_ ] };

declare 'MapStringDisasterRecoveryEvent',
    as HashRef[DisasterRecoveryEvent()];

declare 'Severity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
