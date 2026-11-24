package Google::Cloud::Osconfig::V1alpha::OsPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OSPolicy',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy'];

coerce 'OSPolicy',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy'->new($_) };

declare 'RepeatedOSPolicy',
    as ArrayRef[OSPolicy()];

coerce 'RepeatedOSPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy'->new($_) } @$_ ] };

declare 'MapStringOSPolicy',
    as HashRef[OSPolicy()];

declare 'Mode',
    as (Int | Str);

declare 'OSFilter',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::OSFilter'];

coerce 'OSFilter',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::OSFilter'->new($_) };

declare 'RepeatedOSFilter',
    as ArrayRef[OSFilter()];

coerce 'RepeatedOSFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::OSFilter'->new($_) } @$_ ] };

declare 'MapStringOSFilter',
    as HashRef[OSFilter()];

declare 'InventoryFilter',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::InventoryFilter'];

coerce 'InventoryFilter',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::InventoryFilter'->new($_) };

declare 'RepeatedInventoryFilter',
    as ArrayRef[InventoryFilter()];

coerce 'RepeatedInventoryFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::InventoryFilter'->new($_) } @$_ ] };

declare 'MapStringInventoryFilter',
    as HashRef[InventoryFilter()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'File',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File'];

coerce 'File',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'Remote',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File::Remote'];

coerce 'Remote',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File::Remote'->new($_) };

declare 'RepeatedRemote',
    as ArrayRef[Remote()];

coerce 'RepeatedRemote',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File::Remote'->new($_) } @$_ ] };

declare 'MapStringRemote',
    as HashRef[Remote()];

declare 'Gcs',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File::Gcs'];

coerce 'Gcs',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File::Gcs'->new($_) };

declare 'RepeatedGcs',
    as ArrayRef[Gcs()];

coerce 'RepeatedGcs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::File::Gcs'->new($_) } @$_ ] };

declare 'MapStringGcs',
    as HashRef[Gcs()];

declare 'PackageResource',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource'];

coerce 'PackageResource',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource'->new($_) };

declare 'RepeatedPackageResource',
    as ArrayRef[PackageResource()];

coerce 'RepeatedPackageResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource'->new($_) } @$_ ] };

declare 'MapStringPackageResource',
    as HashRef[PackageResource()];

declare 'DesiredState',
    as (Int | Str);

declare 'Deb',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::Deb'];

coerce 'Deb',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::Deb'->new($_) };

declare 'RepeatedDeb',
    as ArrayRef[Deb()];

coerce 'RepeatedDeb',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::Deb'->new($_) } @$_ ] };

declare 'MapStringDeb',
    as HashRef[Deb()];

declare 'APT',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::APT'];

coerce 'APT',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::APT'->new($_) };

declare 'RepeatedAPT',
    as ArrayRef[APT()];

coerce 'RepeatedAPT',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::APT'->new($_) } @$_ ] };

declare 'MapStringAPT',
    as HashRef[APT()];

declare 'RPM',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::RPM'];

coerce 'RPM',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::RPM'->new($_) };

declare 'RepeatedRPM',
    as ArrayRef[RPM()];

coerce 'RepeatedRPM',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::RPM'->new($_) } @$_ ] };

declare 'MapStringRPM',
    as HashRef[RPM()];

declare 'YUM',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::YUM'];

coerce 'YUM',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::YUM'->new($_) };

declare 'RepeatedYUM',
    as ArrayRef[YUM()];

coerce 'RepeatedYUM',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::YUM'->new($_) } @$_ ] };

declare 'MapStringYUM',
    as HashRef[YUM()];

declare 'Zypper',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::Zypper'];

coerce 'Zypper',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::Zypper'->new($_) };

declare 'RepeatedZypper',
    as ArrayRef[Zypper()];

coerce 'RepeatedZypper',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::Zypper'->new($_) } @$_ ] };

declare 'MapStringZypper',
    as HashRef[Zypper()];

declare 'GooGet',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::GooGet'];

coerce 'GooGet',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::GooGet'->new($_) };

declare 'RepeatedGooGet',
    as ArrayRef[GooGet()];

coerce 'RepeatedGooGet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::GooGet'->new($_) } @$_ ] };

declare 'MapStringGooGet',
    as HashRef[GooGet()];

declare 'MSI',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::MSI'];

coerce 'MSI',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::MSI'->new($_) };

declare 'RepeatedMSI',
    as ArrayRef[MSI()];

coerce 'RepeatedMSI',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::PackageResource::MSI'->new($_) } @$_ ] };

declare 'MapStringMSI',
    as HashRef[MSI()];

declare 'RepositoryResource',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource'];

coerce 'RepositoryResource',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource'->new($_) };

declare 'RepeatedRepositoryResource',
    as ArrayRef[RepositoryResource()];

coerce 'RepeatedRepositoryResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource'->new($_) } @$_ ] };

declare 'MapStringRepositoryResource',
    as HashRef[RepositoryResource()];

declare 'AptRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::AptRepository'];

coerce 'AptRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::AptRepository'->new($_) };

declare 'RepeatedAptRepository',
    as ArrayRef[AptRepository()];

coerce 'RepeatedAptRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::AptRepository'->new($_) } @$_ ] };

declare 'MapStringAptRepository',
    as HashRef[AptRepository()];

declare 'ArchiveType',
    as (Int | Str);

declare 'YumRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::YumRepository'];

coerce 'YumRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::YumRepository'->new($_) };

declare 'RepeatedYumRepository',
    as ArrayRef[YumRepository()];

coerce 'RepeatedYumRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::YumRepository'->new($_) } @$_ ] };

declare 'MapStringYumRepository',
    as HashRef[YumRepository()];

declare 'ZypperRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::ZypperRepository'];

coerce 'ZypperRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::ZypperRepository'->new($_) };

declare 'RepeatedZypperRepository',
    as ArrayRef[ZypperRepository()];

coerce 'RepeatedZypperRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::ZypperRepository'->new($_) } @$_ ] };

declare 'MapStringZypperRepository',
    as HashRef[ZypperRepository()];

declare 'GooRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::GooRepository'];

coerce 'GooRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::GooRepository'->new($_) };

declare 'RepeatedGooRepository',
    as ArrayRef[GooRepository()];

coerce 'RepeatedGooRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::RepositoryResource::GooRepository'->new($_) } @$_ ] };

declare 'MapStringGooRepository',
    as HashRef[GooRepository()];

declare 'ExecResource',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::ExecResource'];

coerce 'ExecResource',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::ExecResource'->new($_) };

declare 'RepeatedExecResource',
    as ArrayRef[ExecResource()];

coerce 'RepeatedExecResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::ExecResource'->new($_) } @$_ ] };

declare 'MapStringExecResource',
    as HashRef[ExecResource()];

declare 'Exec',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::ExecResource::Exec'];

coerce 'Exec',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::ExecResource::Exec'->new($_) };

declare 'RepeatedExec',
    as ArrayRef[Exec()];

coerce 'RepeatedExec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::ExecResource::Exec'->new($_) } @$_ ] };

declare 'MapStringExec',
    as HashRef[Exec()];

declare 'Interpreter',
    as (Int | Str);

declare 'FileResource',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::FileResource'];

coerce 'FileResource',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::FileResource'->new($_) };

declare 'RepeatedFileResource',
    as ArrayRef[FileResource()];

coerce 'RepeatedFileResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::Resource::FileResource'->new($_) } @$_ ] };

declare 'MapStringFileResource',
    as HashRef[FileResource()];

declare 'DesiredState',
    as (Int | Str);

declare 'ResourceGroup',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::ResourceGroup'];

coerce 'ResourceGroup',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::ResourceGroup'->new($_) };

declare 'RepeatedResourceGroup',
    as ArrayRef[ResourceGroup()];

coerce 'RepeatedResourceGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy::ResourceGroup'->new($_) } @$_ ] };

declare 'MapStringResourceGroup',
    as HashRef[ResourceGroup()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1alpha::OsPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
