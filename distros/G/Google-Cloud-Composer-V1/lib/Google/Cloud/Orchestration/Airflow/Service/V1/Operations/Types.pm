package Google::Cloud::Orchestration::Airflow::Service::V1::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Operations::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Operations::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Operations::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
