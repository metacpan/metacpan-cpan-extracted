package Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomMirroringProfile',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::CustomMirroringProfile'];

coerce 'CustomMirroringProfile',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::CustomMirroringProfile'->new($_) };

declare 'RepeatedCustomMirroringProfile',
    as ArrayRef[CustomMirroringProfile()];

coerce 'RepeatedCustomMirroringProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::CustomMirroringProfile'->new($_) } @$_ ] };

declare 'MapStringCustomMirroringProfile',
    as HashRef[CustomMirroringProfile()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
