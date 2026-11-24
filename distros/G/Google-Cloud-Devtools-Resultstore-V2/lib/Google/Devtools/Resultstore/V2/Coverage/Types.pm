package Google::Devtools::Resultstore::V2::Coverage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LineCoverage',
    as InstanceOf['Google::Devtools::Resultstore::V2::Coverage::LineCoverage'];

coerce 'LineCoverage',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Coverage::LineCoverage'->new($_) };

declare 'RepeatedLineCoverage',
    as ArrayRef[LineCoverage()];

coerce 'RepeatedLineCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Coverage::LineCoverage'->new($_) } @$_ ] };

declare 'MapStringLineCoverage',
    as HashRef[LineCoverage()];

declare 'BranchCoverage',
    as InstanceOf['Google::Devtools::Resultstore::V2::Coverage::BranchCoverage'];

coerce 'BranchCoverage',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Coverage::BranchCoverage'->new($_) };

declare 'RepeatedBranchCoverage',
    as ArrayRef[BranchCoverage()];

coerce 'RepeatedBranchCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Coverage::BranchCoverage'->new($_) } @$_ ] };

declare 'MapStringBranchCoverage',
    as HashRef[BranchCoverage()];

declare 'FileCoverage',
    as InstanceOf['Google::Devtools::Resultstore::V2::Coverage::FileCoverage'];

coerce 'FileCoverage',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Coverage::FileCoverage'->new($_) };

declare 'RepeatedFileCoverage',
    as ArrayRef[FileCoverage()];

coerce 'RepeatedFileCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Coverage::FileCoverage'->new($_) } @$_ ] };

declare 'MapStringFileCoverage',
    as HashRef[FileCoverage()];

declare 'ActionCoverage',
    as InstanceOf['Google::Devtools::Resultstore::V2::Coverage::ActionCoverage'];

coerce 'ActionCoverage',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Coverage::ActionCoverage'->new($_) };

declare 'RepeatedActionCoverage',
    as ArrayRef[ActionCoverage()];

coerce 'RepeatedActionCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Coverage::ActionCoverage'->new($_) } @$_ ] };

declare 'MapStringActionCoverage',
    as HashRef[ActionCoverage()];

declare 'AggregateCoverage',
    as InstanceOf['Google::Devtools::Resultstore::V2::Coverage::AggregateCoverage'];

coerce 'AggregateCoverage',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Coverage::AggregateCoverage'->new($_) };

declare 'RepeatedAggregateCoverage',
    as ArrayRef[AggregateCoverage()];

coerce 'RepeatedAggregateCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Coverage::AggregateCoverage'->new($_) } @$_ ] };

declare 'MapStringAggregateCoverage',
    as HashRef[AggregateCoverage()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::Coverage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
