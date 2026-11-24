package Google::Cloud::Designcenter::V1::BestPractices::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssessmentReport',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport'];

coerce 'AssessmentReport',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport'->new($_) };

declare 'RepeatedAssessmentReport',
    as ArrayRef[AssessmentReport()];

coerce 'RepeatedAssessmentReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport'->new($_) } @$_ ] };

declare 'MapStringAssessmentReport',
    as HashRef[AssessmentReport()];

declare 'Policy',
    as InstanceOf['Google::Cloud::Designcenter::V1::BestPractices::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::BestPractices::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::BestPractices::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'PolicyType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::BestPractices::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
