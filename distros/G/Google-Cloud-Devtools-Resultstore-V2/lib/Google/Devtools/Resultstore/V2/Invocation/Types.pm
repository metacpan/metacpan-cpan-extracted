package Google::Devtools::Resultstore::V2::Invocation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Invocation',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::Invocation'];

coerce 'Invocation',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::Invocation'->new($_) };

declare 'RepeatedInvocation',
    as ArrayRef[Invocation()];

coerce 'RepeatedInvocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::Invocation'->new($_) } @$_ ] };

declare 'MapStringInvocation',
    as HashRef[Invocation()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::Invocation::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::Invocation::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::Invocation::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'WorkspaceContext',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::WorkspaceContext'];

coerce 'WorkspaceContext',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::WorkspaceContext'->new($_) };

declare 'RepeatedWorkspaceContext',
    as ArrayRef[WorkspaceContext()];

coerce 'RepeatedWorkspaceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::WorkspaceContext'->new($_) } @$_ ] };

declare 'MapStringWorkspaceContext',
    as HashRef[WorkspaceContext()];

declare 'WorkspaceInfo',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::WorkspaceInfo'];

coerce 'WorkspaceInfo',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::WorkspaceInfo'->new($_) };

declare 'RepeatedWorkspaceInfo',
    as ArrayRef[WorkspaceInfo()];

coerce 'RepeatedWorkspaceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::WorkspaceInfo'->new($_) } @$_ ] };

declare 'MapStringWorkspaceInfo',
    as HashRef[WorkspaceInfo()];

declare 'CommandLine',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::CommandLine'];

coerce 'CommandLine',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::CommandLine'->new($_) };

declare 'RepeatedCommandLine',
    as ArrayRef[CommandLine()];

coerce 'RepeatedCommandLine',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::CommandLine'->new($_) } @$_ ] };

declare 'MapStringCommandLine',
    as HashRef[CommandLine()];

declare 'InvocationAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::InvocationAttributes'];

coerce 'InvocationAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::InvocationAttributes'->new($_) };

declare 'RepeatedInvocationAttributes',
    as ArrayRef[InvocationAttributes()];

coerce 'RepeatedInvocationAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::InvocationAttributes'->new($_) } @$_ ] };

declare 'MapStringInvocationAttributes',
    as HashRef[InvocationAttributes()];

declare 'InvocationContext',
    as InstanceOf['Google::Devtools::Resultstore::V2::Invocation::InvocationContext'];

coerce 'InvocationContext',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Invocation::InvocationContext'->new($_) };

declare 'RepeatedInvocationContext',
    as ArrayRef[InvocationContext()];

coerce 'RepeatedInvocationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Invocation::InvocationContext'->new($_) } @$_ ] };

declare 'MapStringInvocationContext',
    as HashRef[InvocationContext()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::Invocation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
