package Google::Cloud::Documentai::V1::ProcessorType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProcessorType',
    as InstanceOf['Google::Cloud::Documentai::V1::ProcessorType::ProcessorType'];

coerce 'ProcessorType',
    from HashRef, via { 'Google::Cloud::Documentai::V1::ProcessorType::ProcessorType'->new($_) };

declare 'RepeatedProcessorType',
    as ArrayRef[ProcessorType()];

coerce 'RepeatedProcessorType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::ProcessorType::ProcessorType'->new($_) } @$_ ] };

declare 'MapStringProcessorType',
    as HashRef[ProcessorType()];

declare 'LocationInfo',
    as InstanceOf['Google::Cloud::Documentai::V1::ProcessorType::ProcessorType::LocationInfo'];

coerce 'LocationInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1::ProcessorType::ProcessorType::LocationInfo'->new($_) };

declare 'RepeatedLocationInfo',
    as ArrayRef[LocationInfo()];

coerce 'RepeatedLocationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::ProcessorType::ProcessorType::LocationInfo'->new($_) } @$_ ] };

declare 'MapStringLocationInfo',
    as HashRef[LocationInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::ProcessorType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
