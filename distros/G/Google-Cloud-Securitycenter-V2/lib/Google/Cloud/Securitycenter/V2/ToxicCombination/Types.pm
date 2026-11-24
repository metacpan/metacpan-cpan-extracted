package Google::Cloud::Securitycenter::V2::ToxicCombination::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ToxicCombination',
    as InstanceOf['Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination'];

coerce 'ToxicCombination',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination'->new($_) };

declare 'RepeatedToxicCombination',
    as ArrayRef[ToxicCombination()];

coerce 'RepeatedToxicCombination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination'->new($_) } @$_ ] };

declare 'MapStringToxicCombination',
    as HashRef[ToxicCombination()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::ToxicCombination::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
