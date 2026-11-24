package Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EncryptionSpec',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec'];

coerce 'EncryptionSpec',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec'->new($_) };

declare 'RepeatedEncryptionSpec',
    as ArrayRef[EncryptionSpec()];

coerce 'RepeatedEncryptionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec'->new($_) } @$_ ] };

declare 'MapStringEncryptionSpec',
    as HashRef[EncryptionSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
