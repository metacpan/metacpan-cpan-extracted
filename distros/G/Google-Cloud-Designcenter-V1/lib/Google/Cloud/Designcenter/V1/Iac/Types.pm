package Google::Cloud::Designcenter::V1::Iac::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RootModulesMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata'];

coerce 'RootModulesMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata'->new($_) };

declare 'RepeatedRootModulesMetadata',
    as ArrayRef[RootModulesMetadata()];

coerce 'RepeatedRootModulesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata'->new($_) } @$_ ] };

declare 'MapStringRootModulesMetadata',
    as HashRef[RootModulesMetadata()];

declare 'RootModule',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::RootModule'];

coerce 'RootModule',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::RootModule'->new($_) };

declare 'RepeatedRootModule',
    as ArrayRef[RootModule()];

coerce 'RepeatedRootModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::RootModule'->new($_) } @$_ ] };

declare 'MapStringRootModule',
    as HashRef[RootModule()];

declare 'RootModuleDependency',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::RootModuleDependency'];

coerce 'RootModuleDependency',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::RootModuleDependency'->new($_) };

declare 'RepeatedRootModuleDependency',
    as ArrayRef[RootModuleDependency()];

coerce 'RepeatedRootModuleDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::RootModuleDependency'->new($_) } @$_ ] };

declare 'MapStringRootModuleDependency',
    as HashRef[RootModuleDependency()];

declare 'RootInputVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::RootInputVariable'];

coerce 'RootInputVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::RootInputVariable'->new($_) };

declare 'RepeatedRootInputVariable',
    as ArrayRef[RootInputVariable()];

coerce 'RepeatedRootInputVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::RootInputVariable'->new($_) } @$_ ] };

declare 'MapStringRootInputVariable',
    as HashRef[RootInputVariable()];

declare 'RootOutputVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::RootOutputVariable'];

coerce 'RootOutputVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::RootOutputVariable'->new($_) };

declare 'RepeatedRootOutputVariable',
    as ArrayRef[RootOutputVariable()];

coerce 'RepeatedRootOutputVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::RootOutputVariable'->new($_) } @$_ ] };

declare 'MapStringRootOutputVariable',
    as HashRef[RootOutputVariable()];

declare 'TerraformModule',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::TerraformModule'];

coerce 'TerraformModule',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::TerraformModule'->new($_) };

declare 'RepeatedTerraformModule',
    as ArrayRef[TerraformModule()];

coerce 'RepeatedTerraformModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::TerraformModule'->new($_) } @$_ ] };

declare 'MapStringTerraformModule',
    as HashRef[TerraformModule()];

declare 'TerraformFile',
    as InstanceOf['Google::Cloud::Designcenter::V1::Iac::TerraformFile'];

coerce 'TerraformFile',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Iac::TerraformFile'->new($_) };

declare 'RepeatedTerraformFile',
    as ArrayRef[TerraformFile()];

coerce 'RepeatedTerraformFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Iac::TerraformFile'->new($_) } @$_ ] };

declare 'MapStringTerraformFile',
    as HashRef[TerraformFile()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Iac::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
