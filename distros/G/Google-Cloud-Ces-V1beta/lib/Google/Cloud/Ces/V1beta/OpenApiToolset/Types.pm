package Google::Cloud::Ces::V1beta::OpenApiToolset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OpenApiToolset',
    as InstanceOf['Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset'];

coerce 'OpenApiToolset',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset'->new($_) };

declare 'RepeatedOpenApiToolset',
    as ArrayRef[OpenApiToolset()];

coerce 'RepeatedOpenApiToolset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset'->new($_) } @$_ ] };

declare 'MapStringOpenApiToolset',
    as HashRef[OpenApiToolset()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::OpenApiToolset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
