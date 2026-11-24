package Google::Cloud::Automl::V1beta1::Temporal::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TimeSegment',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Temporal::TimeSegment'];

coerce 'TimeSegment',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Temporal::TimeSegment'->new($_) };

declare 'RepeatedTimeSegment',
    as ArrayRef[TimeSegment()];

coerce 'RepeatedTimeSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Temporal::TimeSegment'->new($_) } @$_ ] };

declare 'MapStringTimeSegment',
    as HashRef[TimeSegment()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Temporal::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
