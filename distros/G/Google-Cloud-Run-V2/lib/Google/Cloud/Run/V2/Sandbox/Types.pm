package Google::Cloud::Run::V2::Sandbox::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SandboxConfiguration',
    as InstanceOf['Google::Cloud::Run::V2::Sandbox::SandboxConfiguration'];

coerce 'SandboxConfiguration',
    from HashRef, via { 'Google::Cloud::Run::V2::Sandbox::SandboxConfiguration'->new($_) };

declare 'RepeatedSandboxConfiguration',
    as ArrayRef[SandboxConfiguration()];

coerce 'RepeatedSandboxConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Sandbox::SandboxConfiguration'->new($_) } @$_ ] };

declare 'MapStringSandboxConfiguration',
    as HashRef[SandboxConfiguration()];

declare 'SandboxTemplate',
    as InstanceOf['Google::Cloud::Run::V2::Sandbox::SandboxTemplate'];

coerce 'SandboxTemplate',
    from HashRef, via { 'Google::Cloud::Run::V2::Sandbox::SandboxTemplate'->new($_) };

declare 'RepeatedSandboxTemplate',
    as ArrayRef[SandboxTemplate()];

coerce 'RepeatedSandboxTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Sandbox::SandboxTemplate'->new($_) } @$_ ] };

declare 'MapStringSandboxTemplate',
    as HashRef[SandboxTemplate()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Sandbox::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
