package Grafeas::V1::Risk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Risk',
    as InstanceOf['Grafeas::V1::Risk::Risk'];

coerce 'Risk',
    from HashRef, via { 'Grafeas::V1::Risk::Risk'->new($_) };

declare 'RepeatedRisk',
    as ArrayRef[Risk()];

coerce 'RepeatedRisk',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Risk::Risk'->new($_) } @$_ ] };

declare 'MapStringRisk',
    as HashRef[Risk()];

declare 'CISAKnownExploitedVulnerabilities',
    as InstanceOf['Grafeas::V1::Risk::CISAKnownExploitedVulnerabilities'];

coerce 'CISAKnownExploitedVulnerabilities',
    from HashRef, via { 'Grafeas::V1::Risk::CISAKnownExploitedVulnerabilities'->new($_) };

declare 'RepeatedCISAKnownExploitedVulnerabilities',
    as ArrayRef[CISAKnownExploitedVulnerabilities()];

coerce 'RepeatedCISAKnownExploitedVulnerabilities',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Risk::CISAKnownExploitedVulnerabilities'->new($_) } @$_ ] };

declare 'MapStringCISAKnownExploitedVulnerabilities',
    as HashRef[CISAKnownExploitedVulnerabilities()];

declare 'ExploitPredictionScoringSystem',
    as InstanceOf['Grafeas::V1::Risk::ExploitPredictionScoringSystem'];

coerce 'ExploitPredictionScoringSystem',
    from HashRef, via { 'Grafeas::V1::Risk::ExploitPredictionScoringSystem'->new($_) };

declare 'RepeatedExploitPredictionScoringSystem',
    as ArrayRef[ExploitPredictionScoringSystem()];

coerce 'RepeatedExploitPredictionScoringSystem',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Risk::ExploitPredictionScoringSystem'->new($_) } @$_ ] };

declare 'MapStringExploitPredictionScoringSystem',
    as HashRef[ExploitPredictionScoringSystem()];

1;

__END__

=head1 NAME

Grafeas::V1::Risk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
