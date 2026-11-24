package Google::Cloud::Orgpolicy::V2::Constraint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Constraint',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint'];

coerce 'Constraint',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint'->new($_) };

declare 'RepeatedConstraint',
    as ArrayRef[Constraint()];

coerce 'RepeatedConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint'->new($_) } @$_ ] };

declare 'MapStringConstraint',
    as HashRef[Constraint()];

declare 'ConstraintDefault',
    as (Int | Str);

declare 'ListConstraint',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint::ListConstraint'];

coerce 'ListConstraint',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::ListConstraint'->new($_) };

declare 'RepeatedListConstraint',
    as ArrayRef[ListConstraint()];

coerce 'RepeatedListConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::ListConstraint'->new($_) } @$_ ] };

declare 'MapStringListConstraint',
    as HashRef[ListConstraint()];

declare 'CustomConstraintDefinition',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition'];

coerce 'CustomConstraintDefinition',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition'->new($_) };

declare 'RepeatedCustomConstraintDefinition',
    as ArrayRef[CustomConstraintDefinition()];

coerce 'RepeatedCustomConstraintDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition'->new($_) } @$_ ] };

declare 'MapStringCustomConstraintDefinition',
    as HashRef[CustomConstraintDefinition()];

declare 'MethodType',
    as (Int | Str);

declare 'ActionType',
    as (Int | Str);

declare 'Parameter',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'Type',
    as (Int | Str);

declare 'Metadata',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::Parameter::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::Parameter::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::Parameter::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::CustomConstraintDefinition::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'BooleanConstraint',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::Constraint::BooleanConstraint'];

coerce 'BooleanConstraint',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::BooleanConstraint'->new($_) };

declare 'RepeatedBooleanConstraint',
    as ArrayRef[BooleanConstraint()];

coerce 'RepeatedBooleanConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::Constraint::BooleanConstraint'->new($_) } @$_ ] };

declare 'MapStringBooleanConstraint',
    as HashRef[BooleanConstraint()];

declare 'CustomConstraint',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Constraint::CustomConstraint'];

coerce 'CustomConstraint',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Constraint::CustomConstraint'->new($_) };

declare 'RepeatedCustomConstraint',
    as ArrayRef[CustomConstraint()];

coerce 'RepeatedCustomConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Constraint::CustomConstraint'->new($_) } @$_ ] };

declare 'MapStringCustomConstraint',
    as HashRef[CustomConstraint()];

declare 'MethodType',
    as (Int | Str);

declare 'ActionType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Orgpolicy::V2::Constraint::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
