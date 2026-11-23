package Google::Ai::Generativelanguage::V1beta::Permission::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Permission',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Permission::Permission'];

coerce 'Permission',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Permission::Permission'->new($_) };

declare 'RepeatedPermission',
    as ArrayRef[Permission()];

coerce 'RepeatedPermission',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Permission::Permission'->new($_) } @$_ ] };

declare 'MapStringPermission',
    as HashRef[Permission()];

declare 'GranteeType',
    as (Int | Str);

declare 'Role',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Permission::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
