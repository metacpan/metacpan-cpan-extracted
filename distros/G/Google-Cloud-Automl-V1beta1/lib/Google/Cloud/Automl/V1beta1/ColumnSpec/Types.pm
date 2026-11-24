package Google::Cloud::Automl::V1beta1::ColumnSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ColumnSpec',
    as InstanceOf['Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec'];

coerce 'ColumnSpec',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec'->new($_) };

declare 'RepeatedColumnSpec',
    as ArrayRef[ColumnSpec()];

coerce 'RepeatedColumnSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec'->new($_) } @$_ ] };

declare 'MapStringColumnSpec',
    as HashRef[ColumnSpec()];

declare 'CorrelatedColumn',
    as InstanceOf['Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec::CorrelatedColumn'];

coerce 'CorrelatedColumn',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec::CorrelatedColumn'->new($_) };

declare 'RepeatedCorrelatedColumn',
    as ArrayRef[CorrelatedColumn()];

coerce 'RepeatedCorrelatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec::CorrelatedColumn'->new($_) } @$_ ] };

declare 'MapStringCorrelatedColumn',
    as HashRef[CorrelatedColumn()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::ColumnSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
