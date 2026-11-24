package Google::Cloud::Retail::V2alpha::Branch::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BranchView',
    as (Int | Str);

declare 'Branch',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Branch::Branch'];

coerce 'Branch',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Branch::Branch'->new($_) };

declare 'RepeatedBranch',
    as ArrayRef[Branch()];

coerce 'RepeatedBranch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Branch::Branch'->new($_) } @$_ ] };

declare 'MapStringBranch',
    as HashRef[Branch()];

declare 'ProductCountStatistic',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Branch::Branch::ProductCountStatistic'];

coerce 'ProductCountStatistic',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Branch::Branch::ProductCountStatistic'->new($_) };

declare 'RepeatedProductCountStatistic',
    as ArrayRef[ProductCountStatistic()];

coerce 'RepeatedProductCountStatistic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Branch::Branch::ProductCountStatistic'->new($_) } @$_ ] };

declare 'MapStringProductCountStatistic',
    as HashRef[ProductCountStatistic()];

declare 'ProductCountScope',
    as (Int | Str);

declare 'CountsEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Branch::Branch::ProductCountStatistic::CountsEntry'];

coerce 'CountsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Branch::Branch::ProductCountStatistic::CountsEntry'->new($_) };

declare 'RepeatedCountsEntry',
    as ArrayRef[CountsEntry()];

coerce 'RepeatedCountsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Branch::Branch::ProductCountStatistic::CountsEntry'->new($_) } @$_ ] };

declare 'MapStringCountsEntry',
    as HashRef[CountsEntry()];

declare 'QualityMetric',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Branch::Branch::QualityMetric'];

coerce 'QualityMetric',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Branch::Branch::QualityMetric'->new($_) };

declare 'RepeatedQualityMetric',
    as ArrayRef[QualityMetric()];

coerce 'RepeatedQualityMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Branch::Branch::QualityMetric'->new($_) } @$_ ] };

declare 'MapStringQualityMetric',
    as HashRef[QualityMetric()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::Branch::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
