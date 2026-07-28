package Google::Cloud::Bigquery::V2::Error::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ErrorProto',
    as InstanceOf['Google::Cloud::Bigquery::V2::Error::ErrorProto'];

coerce 'ErrorProto',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Error::ErrorProto'->new($_) };

declare 'RepeatedErrorProto',
    as ArrayRef[ErrorProto()];

coerce 'RepeatedErrorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Error::ErrorProto'->new($_) } @$_ ] };

declare 'MapStringErrorProto',
    as HashRef[ErrorProto()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::Error::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
