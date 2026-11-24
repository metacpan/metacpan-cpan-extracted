package Google::Actions::Sdk::V2::ValidationResults::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValidationResults',
    as InstanceOf['Google::Actions::Sdk::V2::ValidationResults::ValidationResults'];

coerce 'ValidationResults',
    from HashRef, via { 'Google::Actions::Sdk::V2::ValidationResults::ValidationResults'->new($_) };

declare 'RepeatedValidationResults',
    as ArrayRef[ValidationResults()];

coerce 'RepeatedValidationResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ValidationResults::ValidationResults'->new($_) } @$_ ] };

declare 'MapStringValidationResults',
    as HashRef[ValidationResults()];

declare 'ValidationResult',
    as InstanceOf['Google::Actions::Sdk::V2::ValidationResults::ValidationResult'];

coerce 'ValidationResult',
    from HashRef, via { 'Google::Actions::Sdk::V2::ValidationResults::ValidationResult'->new($_) };

declare 'RepeatedValidationResult',
    as ArrayRef[ValidationResult()];

coerce 'RepeatedValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ValidationResults::ValidationResult'->new($_) } @$_ ] };

declare 'MapStringValidationResult',
    as HashRef[ValidationResult()];

declare 'ValidationContext',
    as InstanceOf['Google::Actions::Sdk::V2::ValidationResults::ValidationResult::ValidationContext'];

coerce 'ValidationContext',
    from HashRef, via { 'Google::Actions::Sdk::V2::ValidationResults::ValidationResult::ValidationContext'->new($_) };

declare 'RepeatedValidationContext',
    as ArrayRef[ValidationContext()];

coerce 'RepeatedValidationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ValidationResults::ValidationResult::ValidationContext'->new($_) } @$_ ] };

declare 'MapStringValidationContext',
    as HashRef[ValidationContext()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::ValidationResults::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
