package Google::Firestore::V1::Pipeline::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StructuredPipeline',
    as InstanceOf['Google::Firestore::V1::Pipeline::StructuredPipeline'];

coerce 'StructuredPipeline',
    from HashRef, via { 'Google::Firestore::V1::Pipeline::StructuredPipeline'->new($_) };

declare 'RepeatedStructuredPipeline',
    as ArrayRef[StructuredPipeline()];

coerce 'RepeatedStructuredPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Pipeline::StructuredPipeline'->new($_) } @$_ ] };

declare 'MapStringStructuredPipeline',
    as HashRef[StructuredPipeline()];

declare 'OptionsEntry',
    as InstanceOf['Google::Firestore::V1::Pipeline::StructuredPipeline::OptionsEntry'];

coerce 'OptionsEntry',
    from HashRef, via { 'Google::Firestore::V1::Pipeline::StructuredPipeline::OptionsEntry'->new($_) };

declare 'RepeatedOptionsEntry',
    as ArrayRef[OptionsEntry()];

coerce 'RepeatedOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Pipeline::StructuredPipeline::OptionsEntry'->new($_) } @$_ ] };

declare 'MapStringOptionsEntry',
    as HashRef[OptionsEntry()];

1;

__END__

=head1 NAME

Google::Firestore::V1::Pipeline::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
