package Google::Cloud::Automl::V1beta1::Ranges::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DoubleRange',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Ranges::DoubleRange'];

coerce 'DoubleRange',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Ranges::DoubleRange'->new($_) };

declare 'RepeatedDoubleRange',
    as ArrayRef[DoubleRange()];

coerce 'RepeatedDoubleRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Ranges::DoubleRange'->new($_) } @$_ ] };

declare 'MapStringDoubleRange',
    as HashRef[DoubleRange()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Ranges::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
