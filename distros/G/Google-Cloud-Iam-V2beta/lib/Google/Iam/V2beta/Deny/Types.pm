package Google::Iam::V2beta::Deny::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DenyRule',
    as InstanceOf['Google::Iam::V2beta::Deny::DenyRule'];

coerce 'DenyRule',
    from HashRef, via { 'Google::Iam::V2beta::Deny::DenyRule'->new($_) };

declare 'RepeatedDenyRule',
    as ArrayRef[DenyRule()];

coerce 'RepeatedDenyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2beta::Deny::DenyRule'->new($_) } @$_ ] };

declare 'MapStringDenyRule',
    as HashRef[DenyRule()];

1;

__END__

=head1 NAME

Google::Iam::V2beta::Deny::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
