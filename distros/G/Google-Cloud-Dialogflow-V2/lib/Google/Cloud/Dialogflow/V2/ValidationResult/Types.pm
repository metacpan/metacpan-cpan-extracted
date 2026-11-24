package Google::Cloud::Dialogflow::V2::ValidationResult::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValidationError',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError'];

coerce 'ValidationError',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError'->new($_) };

declare 'RepeatedValidationError',
    as ArrayRef[ValidationError()];

coerce 'RepeatedValidationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError'->new($_) } @$_ ] };

declare 'MapStringValidationError',
    as HashRef[ValidationError()];

declare 'Severity',
    as (Int | Str);

declare 'ValidationResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ValidationResult::ValidationResult'];

coerce 'ValidationResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ValidationResult::ValidationResult'->new($_) };

declare 'RepeatedValidationResult',
    as ArrayRef[ValidationResult()];

coerce 'RepeatedValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ValidationResult::ValidationResult'->new($_) } @$_ ] };

declare 'MapStringValidationResult',
    as HashRef[ValidationResult()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::ValidationResult::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
