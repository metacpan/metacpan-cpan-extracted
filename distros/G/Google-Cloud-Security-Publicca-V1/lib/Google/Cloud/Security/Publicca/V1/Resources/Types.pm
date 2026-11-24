package Google::Cloud::Security::Publicca::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalAccountKey',
    as InstanceOf['Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey'];

coerce 'ExternalAccountKey',
    from HashRef, via { 'Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey'->new($_) };

declare 'RepeatedExternalAccountKey',
    as ArrayRef[ExternalAccountKey()];

coerce 'RepeatedExternalAccountKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey'->new($_) } @$_ ] };

declare 'MapStringExternalAccountKey',
    as HashRef[ExternalAccountKey()];

1;

__END__

=head1 NAME

Google::Cloud::Security::Publicca::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
