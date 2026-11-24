package Google::Cloud::Support::V2beta::Actor::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Actor',
    as InstanceOf['Google::Cloud::Support::V2beta::Actor::Actor'];

coerce 'Actor',
    from HashRef, via { 'Google::Cloud::Support::V2beta::Actor::Actor'->new($_) };

declare 'RepeatedActor',
    as ArrayRef[Actor()];

coerce 'RepeatedActor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::Actor::Actor'->new($_) } @$_ ] };

declare 'MapStringActor',
    as HashRef[Actor()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::Actor::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
