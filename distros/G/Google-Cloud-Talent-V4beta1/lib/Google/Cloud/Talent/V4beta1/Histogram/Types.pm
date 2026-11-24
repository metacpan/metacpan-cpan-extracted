package Google::Cloud::Talent::V4beta1::Histogram::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HistogramQuery',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery'];

coerce 'HistogramQuery',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery'->new($_) };

declare 'RepeatedHistogramQuery',
    as ArrayRef[HistogramQuery()];

coerce 'RepeatedHistogramQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery'->new($_) } @$_ ] };

declare 'MapStringHistogramQuery',
    as HashRef[HistogramQuery()];

declare 'HistogramQueryResult',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult'];

coerce 'HistogramQueryResult',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult'->new($_) };

declare 'RepeatedHistogramQueryResult',
    as ArrayRef[HistogramQueryResult()];

coerce 'RepeatedHistogramQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult'->new($_) } @$_ ] };

declare 'MapStringHistogramQueryResult',
    as HashRef[HistogramQueryResult()];

declare 'HistogramEntry',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult::HistogramEntry'];

coerce 'HistogramEntry',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult::HistogramEntry'->new($_) };

declare 'RepeatedHistogramEntry',
    as ArrayRef[HistogramEntry()];

coerce 'RepeatedHistogramEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult::HistogramEntry'->new($_) } @$_ ] };

declare 'MapStringHistogramEntry',
    as HashRef[HistogramEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::Histogram::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
