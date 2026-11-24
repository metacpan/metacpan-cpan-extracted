package Google::Cloud::Securitycenter::V2::File::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'File',
    as InstanceOf['Google::Cloud::Securitycenter::V2::File::File'];

coerce 'File',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::File::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::File::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'DiskPath',
    as InstanceOf['Google::Cloud::Securitycenter::V2::File::File::DiskPath'];

coerce 'DiskPath',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::File::File::DiskPath'->new($_) };

declare 'RepeatedDiskPath',
    as ArrayRef[DiskPath()];

coerce 'RepeatedDiskPath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::File::File::DiskPath'->new($_) } @$_ ] };

declare 'MapStringDiskPath',
    as HashRef[DiskPath()];

declare 'FileOperation',
    as InstanceOf['Google::Cloud::Securitycenter::V2::File::File::FileOperation'];

coerce 'FileOperation',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::File::File::FileOperation'->new($_) };

declare 'RepeatedFileOperation',
    as ArrayRef[FileOperation()];

coerce 'RepeatedFileOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::File::File::FileOperation'->new($_) } @$_ ] };

declare 'MapStringFileOperation',
    as HashRef[FileOperation()];

declare 'OperationType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::File::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
