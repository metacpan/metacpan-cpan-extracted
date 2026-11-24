package Google::Cloud::Ces::V1::SystemTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SystemTool',
    as InstanceOf['Google::Cloud::Ces::V1::SystemTool::SystemTool'];

coerce 'SystemTool',
    from HashRef, via { 'Google::Cloud::Ces::V1::SystemTool::SystemTool'->new($_) };

declare 'RepeatedSystemTool',
    as ArrayRef[SystemTool()];

coerce 'RepeatedSystemTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SystemTool::SystemTool'->new($_) } @$_ ] };

declare 'MapStringSystemTool',
    as HashRef[SystemTool()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::SystemTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
