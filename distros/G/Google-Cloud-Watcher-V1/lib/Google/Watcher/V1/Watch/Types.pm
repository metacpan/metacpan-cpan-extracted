package Google::Watcher::V1::Watch::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Request',
    as InstanceOf['Google::Watcher::V1::Watch::Request'];

coerce 'Request',
    from HashRef, via { 'Google::Watcher::V1::Watch::Request'->new($_) };

declare 'RepeatedRequest',
    as ArrayRef[Request()];

coerce 'RepeatedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Watcher::V1::Watch::Request'->new($_) } @$_ ] };

declare 'MapStringRequest',
    as HashRef[Request()];

declare 'ChangeBatch',
    as InstanceOf['Google::Watcher::V1::Watch::ChangeBatch'];

coerce 'ChangeBatch',
    from HashRef, via { 'Google::Watcher::V1::Watch::ChangeBatch'->new($_) };

declare 'RepeatedChangeBatch',
    as ArrayRef[ChangeBatch()];

coerce 'RepeatedChangeBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Watcher::V1::Watch::ChangeBatch'->new($_) } @$_ ] };

declare 'MapStringChangeBatch',
    as HashRef[ChangeBatch()];

declare 'Change',
    as InstanceOf['Google::Watcher::V1::Watch::Change'];

coerce 'Change',
    from HashRef, via { 'Google::Watcher::V1::Watch::Change'->new($_) };

declare 'RepeatedChange',
    as ArrayRef[Change()];

coerce 'RepeatedChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Watcher::V1::Watch::Change'->new($_) } @$_ ] };

declare 'MapStringChange',
    as HashRef[Change()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Watcher::V1::Watch::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
