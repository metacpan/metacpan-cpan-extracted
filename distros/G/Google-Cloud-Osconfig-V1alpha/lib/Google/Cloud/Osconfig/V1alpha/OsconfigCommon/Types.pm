package Google::Cloud::Osconfig::V1alpha::OsconfigCommon::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FixedOrPercent',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent'];

coerce 'FixedOrPercent',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent'->new($_) };

declare 'RepeatedFixedOrPercent',
    as ArrayRef[FixedOrPercent()];

coerce 'RepeatedFixedOrPercent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent'->new($_) } @$_ ] };

declare 'MapStringFixedOrPercent',
    as HashRef[FixedOrPercent()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1alpha::OsconfigCommon::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
