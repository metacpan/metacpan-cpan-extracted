package Grafeas::V1::Compliance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComplianceNote',
    as InstanceOf['Grafeas::V1::Compliance::ComplianceNote'];

coerce 'ComplianceNote',
    from HashRef, via { 'Grafeas::V1::Compliance::ComplianceNote'->new($_) };

declare 'RepeatedComplianceNote',
    as ArrayRef[ComplianceNote()];

coerce 'RepeatedComplianceNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Compliance::ComplianceNote'->new($_) } @$_ ] };

declare 'MapStringComplianceNote',
    as HashRef[ComplianceNote()];

declare 'CisBenchmark',
    as InstanceOf['Grafeas::V1::Compliance::ComplianceNote::CisBenchmark'];

coerce 'CisBenchmark',
    from HashRef, via { 'Grafeas::V1::Compliance::ComplianceNote::CisBenchmark'->new($_) };

declare 'RepeatedCisBenchmark',
    as ArrayRef[CisBenchmark()];

coerce 'RepeatedCisBenchmark',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Compliance::ComplianceNote::CisBenchmark'->new($_) } @$_ ] };

declare 'MapStringCisBenchmark',
    as HashRef[CisBenchmark()];

declare 'ComplianceVersion',
    as InstanceOf['Grafeas::V1::Compliance::ComplianceVersion'];

coerce 'ComplianceVersion',
    from HashRef, via { 'Grafeas::V1::Compliance::ComplianceVersion'->new($_) };

declare 'RepeatedComplianceVersion',
    as ArrayRef[ComplianceVersion()];

coerce 'RepeatedComplianceVersion',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Compliance::ComplianceVersion'->new($_) } @$_ ] };

declare 'MapStringComplianceVersion',
    as HashRef[ComplianceVersion()];

declare 'ComplianceOccurrence',
    as InstanceOf['Grafeas::V1::Compliance::ComplianceOccurrence'];

coerce 'ComplianceOccurrence',
    from HashRef, via { 'Grafeas::V1::Compliance::ComplianceOccurrence'->new($_) };

declare 'RepeatedComplianceOccurrence',
    as ArrayRef[ComplianceOccurrence()];

coerce 'RepeatedComplianceOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Compliance::ComplianceOccurrence'->new($_) } @$_ ] };

declare 'MapStringComplianceOccurrence',
    as HashRef[ComplianceOccurrence()];

declare 'NonCompliantFile',
    as InstanceOf['Grafeas::V1::Compliance::NonCompliantFile'];

coerce 'NonCompliantFile',
    from HashRef, via { 'Grafeas::V1::Compliance::NonCompliantFile'->new($_) };

declare 'RepeatedNonCompliantFile',
    as ArrayRef[NonCompliantFile()];

coerce 'RepeatedNonCompliantFile',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Compliance::NonCompliantFile'->new($_) } @$_ ] };

declare 'MapStringNonCompliantFile',
    as HashRef[NonCompliantFile()];

1;

__END__

=head1 NAME

Grafeas::V1::Compliance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
