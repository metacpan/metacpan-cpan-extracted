package Google::Spanner::V1::Mutation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Mutation',
    as InstanceOf['Google::Spanner::V1::Mutation::Mutation'];

coerce 'Mutation',
    from HashRef, via { 'Google::Spanner::V1::Mutation::Mutation'->new($_) };

declare 'RepeatedMutation',
    as ArrayRef[Mutation()];

coerce 'RepeatedMutation',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Mutation::Mutation'->new($_) } @$_ ] };

declare 'MapStringMutation',
    as HashRef[Mutation()];

declare 'Write',
    as InstanceOf['Google::Spanner::V1::Mutation::Mutation::Write'];

coerce 'Write',
    from HashRef, via { 'Google::Spanner::V1::Mutation::Mutation::Write'->new($_) };

declare 'RepeatedWrite',
    as ArrayRef[Write()];

coerce 'RepeatedWrite',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Mutation::Mutation::Write'->new($_) } @$_ ] };

declare 'MapStringWrite',
    as HashRef[Write()];

declare 'Delete',
    as InstanceOf['Google::Spanner::V1::Mutation::Mutation::Delete'];

coerce 'Delete',
    from HashRef, via { 'Google::Spanner::V1::Mutation::Mutation::Delete'->new($_) };

declare 'RepeatedDelete',
    as ArrayRef[Delete()];

coerce 'RepeatedDelete',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Mutation::Mutation::Delete'->new($_) } @$_ ] };

declare 'MapStringDelete',
    as HashRef[Delete()];

declare 'Send',
    as InstanceOf['Google::Spanner::V1::Mutation::Mutation::Send'];

coerce 'Send',
    from HashRef, via { 'Google::Spanner::V1::Mutation::Mutation::Send'->new($_) };

declare 'RepeatedSend',
    as ArrayRef[Send()];

coerce 'RepeatedSend',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Mutation::Mutation::Send'->new($_) } @$_ ] };

declare 'MapStringSend',
    as HashRef[Send()];

declare 'Ack',
    as InstanceOf['Google::Spanner::V1::Mutation::Mutation::Ack'];

coerce 'Ack',
    from HashRef, via { 'Google::Spanner::V1::Mutation::Mutation::Ack'->new($_) };

declare 'RepeatedAck',
    as ArrayRef[Ack()];

coerce 'RepeatedAck',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Mutation::Mutation::Ack'->new($_) } @$_ ] };

declare 'MapStringAck',
    as HashRef[Ack()];

1;

__END__

=head1 NAME

Google::Spanner::V1::Mutation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
