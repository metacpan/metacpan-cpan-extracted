package Google::Cloud::Ces::V1beta::OpenApiTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OpenApiTool',
    as InstanceOf['Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool'];

coerce 'OpenApiTool',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool'->new($_) };

declare 'RepeatedOpenApiTool',
    as ArrayRef[OpenApiTool()];

coerce 'RepeatedOpenApiTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool'->new($_) } @$_ ] };

declare 'MapStringOpenApiTool',
    as HashRef[OpenApiTool()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::OpenApiTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
