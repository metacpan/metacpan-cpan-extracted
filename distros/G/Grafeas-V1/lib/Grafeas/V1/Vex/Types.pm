package Grafeas::V1::Vex::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VulnerabilityAssessmentNote',
    as InstanceOf['Grafeas::V1::Vex::VulnerabilityAssessmentNote'];

coerce 'VulnerabilityAssessmentNote',
    from HashRef, via { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote'->new($_) };

declare 'RepeatedVulnerabilityAssessmentNote',
    as ArrayRef[VulnerabilityAssessmentNote()];

coerce 'RepeatedVulnerabilityAssessmentNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote'->new($_) } @$_ ] };

declare 'MapStringVulnerabilityAssessmentNote',
    as HashRef[VulnerabilityAssessmentNote()];

declare 'Publisher',
    as InstanceOf['Grafeas::V1::Vex::VulnerabilityAssessmentNote::Publisher'];

coerce 'Publisher',
    from HashRef, via { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Publisher'->new($_) };

declare 'RepeatedPublisher',
    as ArrayRef[Publisher()];

coerce 'RepeatedPublisher',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Publisher'->new($_) } @$_ ] };

declare 'MapStringPublisher',
    as HashRef[Publisher()];

declare 'Product',
    as InstanceOf['Grafeas::V1::Vex::VulnerabilityAssessmentNote::Product'];

coerce 'Product',
    from HashRef, via { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

declare 'Assessment',
    as InstanceOf['Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment'];

coerce 'Assessment',
    from HashRef, via { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment'->new($_) };

declare 'RepeatedAssessment',
    as ArrayRef[Assessment()];

coerce 'RepeatedAssessment',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment'->new($_) } @$_ ] };

declare 'MapStringAssessment',
    as HashRef[Assessment()];

declare 'State',
    as (Int | Str);

declare 'Justification',
    as InstanceOf['Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment::Justification'];

coerce 'Justification',
    from HashRef, via { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment::Justification'->new($_) };

declare 'RepeatedJustification',
    as ArrayRef[Justification()];

coerce 'RepeatedJustification',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment::Justification'->new($_) } @$_ ] };

declare 'MapStringJustification',
    as HashRef[Justification()];

declare 'JustificationType',
    as (Int | Str);

declare 'Remediation',
    as InstanceOf['Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment::Remediation'];

coerce 'Remediation',
    from HashRef, via { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment::Remediation'->new($_) };

declare 'RepeatedRemediation',
    as ArrayRef[Remediation()];

coerce 'RepeatedRemediation',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Vex::VulnerabilityAssessmentNote::Assessment::Remediation'->new($_) } @$_ ] };

declare 'MapStringRemediation',
    as HashRef[Remediation()];

declare 'RemediationType',
    as (Int | Str);

1;

__END__

=head1 NAME

Grafeas::V1::Vex::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
