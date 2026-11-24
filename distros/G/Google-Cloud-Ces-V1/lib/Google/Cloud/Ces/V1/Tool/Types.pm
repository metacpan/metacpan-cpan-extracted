package Google::Cloud::Ces::V1::Tool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Tool',
    as InstanceOf['Google::Cloud::Ces::V1::Tool::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Cloud::Ces::V1::Tool::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Tool::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Tool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
