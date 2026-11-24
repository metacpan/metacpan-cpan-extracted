package Google::Appengine::V1beta::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instance',
    as InstanceOf['Google::Appengine::V1beta::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Appengine::V1beta::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'Availability',
    as (Int | Str);

declare 'Liveness',
    as InstanceOf['Google::Appengine::V1beta::Instance::Instance::Liveness'];

coerce 'Liveness',
    from HashRef, via { 'Google::Appengine::V1beta::Instance::Instance::Liveness'->new($_) };

declare 'RepeatedLiveness',
    as ArrayRef[Liveness()];

coerce 'RepeatedLiveness',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Instance::Instance::Liveness'->new($_) } @$_ ] };

declare 'MapStringLiveness',
    as HashRef[Liveness()];

declare 'LivenessState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Appengine::V1beta::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
