package Google::Cloud::Run::V2::ContainerStatus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ContainerStatus',
    as InstanceOf['Google::Cloud::Run::V2::ContainerStatus::ContainerStatus'];

coerce 'ContainerStatus',
    from HashRef, via { 'Google::Cloud::Run::V2::ContainerStatus::ContainerStatus'->new($_) };

declare 'RepeatedContainerStatus',
    as ArrayRef[ContainerStatus()];

coerce 'RepeatedContainerStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::ContainerStatus::ContainerStatus'->new($_) } @$_ ] };

declare 'MapStringContainerStatus',
    as HashRef[ContainerStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::ContainerStatus::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
