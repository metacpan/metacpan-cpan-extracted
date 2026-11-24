package Google::Cloud::Notebooks::V1::Schedule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Schedule',
    as InstanceOf['Google::Cloud::Notebooks::V1::Schedule::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Schedule::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Schedule::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::Schedule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
