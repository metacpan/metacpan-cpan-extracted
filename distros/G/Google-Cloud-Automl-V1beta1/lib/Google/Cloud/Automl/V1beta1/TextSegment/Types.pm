package Google::Cloud::Automl::V1beta1::TextSegment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TextSegment',
    as InstanceOf['Google::Cloud::Automl::V1beta1::TextSegment::TextSegment'];

coerce 'TextSegment',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::TextSegment::TextSegment'->new($_) };

declare 'RepeatedTextSegment',
    as ArrayRef[TextSegment()];

coerce 'RepeatedTextSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::TextSegment::TextSegment'->new($_) } @$_ ] };

declare 'MapStringTextSegment',
    as HashRef[TextSegment()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::TextSegment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
