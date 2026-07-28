package Google::Iam::V1::Options::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetPolicyOptions',
    as InstanceOf['Google::Iam::V1::Options::GetPolicyOptions'];

coerce 'GetPolicyOptions',
    from HashRef, via { 'Google::Iam::V1::Options::GetPolicyOptions'->new($_) };

declare 'RepeatedGetPolicyOptions',
    as ArrayRef[GetPolicyOptions()];

coerce 'RepeatedGetPolicyOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Options::GetPolicyOptions'->new($_) } @$_ ] };

declare 'MapStringGetPolicyOptions',
    as HashRef[GetPolicyOptions()];

1;

__END__

=head1 NAME

Google::Iam::V1::Options::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
