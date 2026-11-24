package Google::Cloud::Notebooks::V1beta1::Environment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Environment',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Environment::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Environment::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Environment::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'VmImage',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Environment::VmImage'];

coerce 'VmImage',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Environment::VmImage'->new($_) };

declare 'RepeatedVmImage',
    as ArrayRef[VmImage()];

coerce 'RepeatedVmImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Environment::VmImage'->new($_) } @$_ ] };

declare 'MapStringVmImage',
    as HashRef[VmImage()];

declare 'ContainerImage',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage'];

coerce 'ContainerImage',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage'->new($_) };

declare 'RepeatedContainerImage',
    as ArrayRef[ContainerImage()];

coerce 'RepeatedContainerImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage'->new($_) } @$_ ] };

declare 'MapStringContainerImage',
    as HashRef[ContainerImage()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1beta1::Environment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
