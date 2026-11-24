package Google::Appengine::V1::Deploy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Deployment',
    as InstanceOf['Google::Appengine::V1::Deploy::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Appengine::V1::Deploy::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Deploy::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'FilesEntry',
    as InstanceOf['Google::Appengine::V1::Deploy::Deployment::FilesEntry'];

coerce 'FilesEntry',
    from HashRef, via { 'Google::Appengine::V1::Deploy::Deployment::FilesEntry'->new($_) };

declare 'RepeatedFilesEntry',
    as ArrayRef[FilesEntry()];

coerce 'RepeatedFilesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Deploy::Deployment::FilesEntry'->new($_) } @$_ ] };

declare 'MapStringFilesEntry',
    as HashRef[FilesEntry()];

declare 'FileInfo',
    as InstanceOf['Google::Appengine::V1::Deploy::FileInfo'];

coerce 'FileInfo',
    from HashRef, via { 'Google::Appengine::V1::Deploy::FileInfo'->new($_) };

declare 'RepeatedFileInfo',
    as ArrayRef[FileInfo()];

coerce 'RepeatedFileInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Deploy::FileInfo'->new($_) } @$_ ] };

declare 'MapStringFileInfo',
    as HashRef[FileInfo()];

declare 'ContainerInfo',
    as InstanceOf['Google::Appengine::V1::Deploy::ContainerInfo'];

coerce 'ContainerInfo',
    from HashRef, via { 'Google::Appengine::V1::Deploy::ContainerInfo'->new($_) };

declare 'RepeatedContainerInfo',
    as ArrayRef[ContainerInfo()];

coerce 'RepeatedContainerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Deploy::ContainerInfo'->new($_) } @$_ ] };

declare 'MapStringContainerInfo',
    as HashRef[ContainerInfo()];

declare 'CloudBuildOptions',
    as InstanceOf['Google::Appengine::V1::Deploy::CloudBuildOptions'];

coerce 'CloudBuildOptions',
    from HashRef, via { 'Google::Appengine::V1::Deploy::CloudBuildOptions'->new($_) };

declare 'RepeatedCloudBuildOptions',
    as ArrayRef[CloudBuildOptions()];

coerce 'RepeatedCloudBuildOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Deploy::CloudBuildOptions'->new($_) } @$_ ] };

declare 'MapStringCloudBuildOptions',
    as HashRef[CloudBuildOptions()];

declare 'ZipInfo',
    as InstanceOf['Google::Appengine::V1::Deploy::ZipInfo'];

coerce 'ZipInfo',
    from HashRef, via { 'Google::Appengine::V1::Deploy::ZipInfo'->new($_) };

declare 'RepeatedZipInfo',
    as ArrayRef[ZipInfo()];

coerce 'RepeatedZipInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Deploy::ZipInfo'->new($_) } @$_ ] };

declare 'MapStringZipInfo',
    as HashRef[ZipInfo()];

1;

__END__

=head1 NAME

Google::Appengine::V1::Deploy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
