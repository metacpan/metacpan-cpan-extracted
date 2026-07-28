package Google::Iam::V1::ResourcePolicyMember::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourcePolicyMember',
    as InstanceOf['Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember'];

coerce 'ResourcePolicyMember',
    from HashRef, via { 'Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember'->new($_) };

declare 'RepeatedResourcePolicyMember',
    as ArrayRef[ResourcePolicyMember()];

coerce 'RepeatedResourcePolicyMember',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember'->new($_) } @$_ ] };

declare 'MapStringResourcePolicyMember',
    as HashRef[ResourcePolicyMember()];

1;

__END__

=head1 NAME

Google::Iam::V1::ResourcePolicyMember::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
