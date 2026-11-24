package Google::Cloud::Support::V2beta::Escalation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Escalation',
    as InstanceOf['Google::Cloud::Support::V2beta::Escalation::Escalation'];

coerce 'Escalation',
    from HashRef, via { 'Google::Cloud::Support::V2beta::Escalation::Escalation'->new($_) };

declare 'RepeatedEscalation',
    as ArrayRef[Escalation()];

coerce 'RepeatedEscalation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::Escalation::Escalation'->new($_) } @$_ ] };

declare 'MapStringEscalation',
    as HashRef[Escalation()];

declare 'Reason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::Escalation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
