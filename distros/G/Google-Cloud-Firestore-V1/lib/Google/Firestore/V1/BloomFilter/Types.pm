package Google::Firestore::V1::BloomFilter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BitSequence',
    as InstanceOf['Google::Firestore::V1::BloomFilter::BitSequence'];

coerce 'BitSequence',
    from HashRef, via { 'Google::Firestore::V1::BloomFilter::BitSequence'->new($_) };

declare 'RepeatedBitSequence',
    as ArrayRef[BitSequence()];

coerce 'RepeatedBitSequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::BloomFilter::BitSequence'->new($_) } @$_ ] };

declare 'MapStringBitSequence',
    as HashRef[BitSequence()];

declare 'BloomFilter',
    as InstanceOf['Google::Firestore::V1::BloomFilter::BloomFilter'];

coerce 'BloomFilter',
    from HashRef, via { 'Google::Firestore::V1::BloomFilter::BloomFilter'->new($_) };

declare 'RepeatedBloomFilter',
    as ArrayRef[BloomFilter()];

coerce 'RepeatedBloomFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::BloomFilter::BloomFilter'->new($_) } @$_ ] };

declare 'MapStringBloomFilter',
    as HashRef[BloomFilter()];

1;

__END__

=head1 NAME

Google::Firestore::V1::BloomFilter::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
