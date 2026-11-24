package Grafeas::V1::Package::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Architecture',
    as (Int | Str);

declare 'Distribution',
    as InstanceOf['Grafeas::V1::Package::Distribution'];

coerce 'Distribution',
    from HashRef, via { 'Grafeas::V1::Package::Distribution'->new($_) };

declare 'RepeatedDistribution',
    as ArrayRef[Distribution()];

coerce 'RepeatedDistribution',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Package::Distribution'->new($_) } @$_ ] };

declare 'MapStringDistribution',
    as HashRef[Distribution()];

declare 'Location',
    as InstanceOf['Grafeas::V1::Package::Location'];

coerce 'Location',
    from HashRef, via { 'Grafeas::V1::Package::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Package::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'PackageNote',
    as InstanceOf['Grafeas::V1::Package::PackageNote'];

coerce 'PackageNote',
    from HashRef, via { 'Grafeas::V1::Package::PackageNote'->new($_) };

declare 'RepeatedPackageNote',
    as ArrayRef[PackageNote()];

coerce 'RepeatedPackageNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Package::PackageNote'->new($_) } @$_ ] };

declare 'MapStringPackageNote',
    as HashRef[PackageNote()];

declare 'PackageOccurrence',
    as InstanceOf['Grafeas::V1::Package::PackageOccurrence'];

coerce 'PackageOccurrence',
    from HashRef, via { 'Grafeas::V1::Package::PackageOccurrence'->new($_) };

declare 'RepeatedPackageOccurrence',
    as ArrayRef[PackageOccurrence()];

coerce 'RepeatedPackageOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Package::PackageOccurrence'->new($_) } @$_ ] };

declare 'MapStringPackageOccurrence',
    as HashRef[PackageOccurrence()];

declare 'Version',
    as InstanceOf['Grafeas::V1::Package::Version'];

coerce 'Version',
    from HashRef, via { 'Grafeas::V1::Package::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Package::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'VersionKind',
    as (Int | Str);

1;

__END__

=head1 NAME

Grafeas::V1::Package::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
