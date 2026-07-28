package Google::Cloud::Bigquery::V2::EncryptionConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EncryptionConfiguration',
    as InstanceOf['Google::Cloud::Bigquery::V2::EncryptionConfig::EncryptionConfiguration'];

coerce 'EncryptionConfiguration',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::EncryptionConfig::EncryptionConfiguration'->new($_) };

declare 'RepeatedEncryptionConfiguration',
    as ArrayRef[EncryptionConfiguration()];

coerce 'RepeatedEncryptionConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::EncryptionConfig::EncryptionConfiguration'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfiguration',
    as HashRef[EncryptionConfiguration()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::EncryptionConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
