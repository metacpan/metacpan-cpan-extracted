package Google::Actions::Sdk::V2::Manifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Manifest',
    as InstanceOf['Google::Actions::Sdk::V2::Manifest::Manifest'];

coerce 'Manifest',
    from HashRef, via { 'Google::Actions::Sdk::V2::Manifest::Manifest'->new($_) };

declare 'RepeatedManifest',
    as ArrayRef[Manifest()];

coerce 'RepeatedManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Manifest::Manifest'->new($_) } @$_ ] };

declare 'MapStringManifest',
    as HashRef[Manifest()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Manifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
