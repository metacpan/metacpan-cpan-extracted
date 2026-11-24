package Google::Cloud::Run::V2::InstanceSplit::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InstanceSplitAllocationType',
    as (Int | Str);

declare 'InstanceSplit',
    as InstanceOf['Google::Cloud::Run::V2::InstanceSplit::InstanceSplit'];

coerce 'InstanceSplit',
    from HashRef, via { 'Google::Cloud::Run::V2::InstanceSplit::InstanceSplit'->new($_) };

declare 'RepeatedInstanceSplit',
    as ArrayRef[InstanceSplit()];

coerce 'RepeatedInstanceSplit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::InstanceSplit::InstanceSplit'->new($_) } @$_ ] };

declare 'MapStringInstanceSplit',
    as HashRef[InstanceSplit()];

declare 'InstanceSplitStatus',
    as InstanceOf['Google::Cloud::Run::V2::InstanceSplit::InstanceSplitStatus'];

coerce 'InstanceSplitStatus',
    from HashRef, via { 'Google::Cloud::Run::V2::InstanceSplit::InstanceSplitStatus'->new($_) };

declare 'RepeatedInstanceSplitStatus',
    as ArrayRef[InstanceSplitStatus()];

coerce 'RepeatedInstanceSplitStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::InstanceSplit::InstanceSplitStatus'->new($_) } @$_ ] };

declare 'MapStringInstanceSplitStatus',
    as HashRef[InstanceSplitStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::InstanceSplit::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
