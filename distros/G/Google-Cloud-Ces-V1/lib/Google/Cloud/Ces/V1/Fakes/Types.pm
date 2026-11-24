package Google::Cloud::Ces::V1::Fakes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CodeBlock',
    as InstanceOf['Google::Cloud::Ces::V1::Fakes::CodeBlock'];

coerce 'CodeBlock',
    from HashRef, via { 'Google::Cloud::Ces::V1::Fakes::CodeBlock'->new($_) };

declare 'RepeatedCodeBlock',
    as ArrayRef[CodeBlock()];

coerce 'RepeatedCodeBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Fakes::CodeBlock'->new($_) } @$_ ] };

declare 'MapStringCodeBlock',
    as HashRef[CodeBlock()];

declare 'ToolFakeConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Fakes::ToolFakeConfig'];

coerce 'ToolFakeConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Fakes::ToolFakeConfig'->new($_) };

declare 'RepeatedToolFakeConfig',
    as ArrayRef[ToolFakeConfig()];

coerce 'RepeatedToolFakeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Fakes::ToolFakeConfig'->new($_) } @$_ ] };

declare 'MapStringToolFakeConfig',
    as HashRef[ToolFakeConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Fakes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
