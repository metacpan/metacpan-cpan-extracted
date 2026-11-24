package Google::Devtools::Resultstore::V2::CoverageSummary::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LineCoverageSummary',
    as InstanceOf['Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary'];

coerce 'LineCoverageSummary',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary'->new($_) };

declare 'RepeatedLineCoverageSummary',
    as ArrayRef[LineCoverageSummary()];

coerce 'RepeatedLineCoverageSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary'->new($_) } @$_ ] };

declare 'MapStringLineCoverageSummary',
    as HashRef[LineCoverageSummary()];

declare 'BranchCoverageSummary',
    as InstanceOf['Google::Devtools::Resultstore::V2::CoverageSummary::BranchCoverageSummary'];

coerce 'BranchCoverageSummary',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::CoverageSummary::BranchCoverageSummary'->new($_) };

declare 'RepeatedBranchCoverageSummary',
    as ArrayRef[BranchCoverageSummary()];

coerce 'RepeatedBranchCoverageSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::CoverageSummary::BranchCoverageSummary'->new($_) } @$_ ] };

declare 'MapStringBranchCoverageSummary',
    as HashRef[BranchCoverageSummary()];

declare 'LanguageCoverageSummary',
    as InstanceOf['Google::Devtools::Resultstore::V2::CoverageSummary::LanguageCoverageSummary'];

coerce 'LanguageCoverageSummary',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::CoverageSummary::LanguageCoverageSummary'->new($_) };

declare 'RepeatedLanguageCoverageSummary',
    as ArrayRef[LanguageCoverageSummary()];

coerce 'RepeatedLanguageCoverageSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::CoverageSummary::LanguageCoverageSummary'->new($_) } @$_ ] };

declare 'MapStringLanguageCoverageSummary',
    as HashRef[LanguageCoverageSummary()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::CoverageSummary::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
