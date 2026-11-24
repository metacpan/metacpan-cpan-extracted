package Google::Cloud::Automl::V1::ModelEvaluation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ModelEvaluation',
    as InstanceOf['Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation'];

coerce 'ModelEvaluation',
    from HashRef, via { 'Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation'->new($_) };

declare 'RepeatedModelEvaluation',
    as ArrayRef[ModelEvaluation()];

coerce 'RepeatedModelEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation'->new($_) } @$_ ] };

declare 'MapStringModelEvaluation',
    as HashRef[ModelEvaluation()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::ModelEvaluation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
