package Google::Devtools::Artifactregistry::V1::Package::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Package',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::Package'];

coerce 'Package',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::Package'->new($_) };

declare 'RepeatedPackage',
    as ArrayRef[Package()];

coerce 'RepeatedPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::Package'->new($_) } @$_ ] };

declare 'MapStringPackage',
    as HashRef[Package()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::Package::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::Package::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::Package::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ListPackagesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::ListPackagesRequest'];

coerce 'ListPackagesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::ListPackagesRequest'->new($_) };

declare 'RepeatedListPackagesRequest',
    as ArrayRef[ListPackagesRequest()];

coerce 'RepeatedListPackagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::ListPackagesRequest'->new($_) } @$_ ] };

declare 'MapStringListPackagesRequest',
    as HashRef[ListPackagesRequest()];

declare 'ListPackagesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::ListPackagesResponse'];

coerce 'ListPackagesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::ListPackagesResponse'->new($_) };

declare 'RepeatedListPackagesResponse',
    as ArrayRef[ListPackagesResponse()];

coerce 'RepeatedListPackagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::ListPackagesResponse'->new($_) } @$_ ] };

declare 'MapStringListPackagesResponse',
    as HashRef[ListPackagesResponse()];

declare 'GetPackageRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::GetPackageRequest'];

coerce 'GetPackageRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::GetPackageRequest'->new($_) };

declare 'RepeatedGetPackageRequest',
    as ArrayRef[GetPackageRequest()];

coerce 'RepeatedGetPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::GetPackageRequest'->new($_) } @$_ ] };

declare 'MapStringGetPackageRequest',
    as HashRef[GetPackageRequest()];

declare 'DeletePackageRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::DeletePackageRequest'];

coerce 'DeletePackageRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::DeletePackageRequest'->new($_) };

declare 'RepeatedDeletePackageRequest',
    as ArrayRef[DeletePackageRequest()];

coerce 'RepeatedDeletePackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::DeletePackageRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePackageRequest',
    as HashRef[DeletePackageRequest()];

declare 'UpdatePackageRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Package::UpdatePackageRequest'];

coerce 'UpdatePackageRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Package::UpdatePackageRequest'->new($_) };

declare 'RepeatedUpdatePackageRequest',
    as ArrayRef[UpdatePackageRequest()];

coerce 'RepeatedUpdatePackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Package::UpdatePackageRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePackageRequest',
    as HashRef[UpdatePackageRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Package::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
