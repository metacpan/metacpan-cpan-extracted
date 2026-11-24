package Google::Cloud::Ces::V1::ClientFunction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClientFunction',
    as InstanceOf['Google::Cloud::Ces::V1::ClientFunction::ClientFunction'];

coerce 'ClientFunction',
    from HashRef, via { 'Google::Cloud::Ces::V1::ClientFunction::ClientFunction'->new($_) };

declare 'RepeatedClientFunction',
    as ArrayRef[ClientFunction()];

coerce 'RepeatedClientFunction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::ClientFunction::ClientFunction'->new($_) } @$_ ] };

declare 'MapStringClientFunction',
    as HashRef[ClientFunction()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::ClientFunction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
