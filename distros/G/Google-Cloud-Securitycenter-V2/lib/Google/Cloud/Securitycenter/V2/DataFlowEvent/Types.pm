package Google::Cloud::Securitycenter::V2::DataFlowEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFlowEvent',
    as InstanceOf['Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent'];

coerce 'DataFlowEvent',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent'->new($_) };

declare 'RepeatedDataFlowEvent',
    as ArrayRef[DataFlowEvent()];

coerce 'RepeatedDataFlowEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent'->new($_) } @$_ ] };

declare 'MapStringDataFlowEvent',
    as HashRef[DataFlowEvent()];

declare 'Operation',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::DataFlowEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
