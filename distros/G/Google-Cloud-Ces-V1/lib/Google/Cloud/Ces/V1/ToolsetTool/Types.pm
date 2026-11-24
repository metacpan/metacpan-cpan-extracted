package Google::Cloud::Ces::V1::ToolsetTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ToolsetTool',
    as InstanceOf['Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool'];

coerce 'ToolsetTool',
    from HashRef, via { 'Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool'->new($_) };

declare 'RepeatedToolsetTool',
    as ArrayRef[ToolsetTool()];

coerce 'RepeatedToolsetTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool'->new($_) } @$_ ] };

declare 'MapStringToolsetTool',
    as HashRef[ToolsetTool()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::ToolsetTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
