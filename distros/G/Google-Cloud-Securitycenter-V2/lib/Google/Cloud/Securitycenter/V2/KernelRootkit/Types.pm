package Google::Cloud::Securitycenter::V2::KernelRootkit::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KernelRootkit',
    as InstanceOf['Google::Cloud::Securitycenter::V2::KernelRootkit::KernelRootkit'];

coerce 'KernelRootkit',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::KernelRootkit::KernelRootkit'->new($_) };

declare 'RepeatedKernelRootkit',
    as ArrayRef[KernelRootkit()];

coerce 'RepeatedKernelRootkit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::KernelRootkit::KernelRootkit'->new($_) } @$_ ] };

declare 'MapStringKernelRootkit',
    as HashRef[KernelRootkit()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::KernelRootkit::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
