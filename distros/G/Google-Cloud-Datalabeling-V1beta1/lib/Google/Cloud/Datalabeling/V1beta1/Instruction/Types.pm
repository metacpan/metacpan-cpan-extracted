package Google::Cloud::Datalabeling::V1beta1::Instruction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instruction',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction'];

coerce 'Instruction',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction'->new($_) };

declare 'RepeatedInstruction',
    as ArrayRef[Instruction()];

coerce 'RepeatedInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction'->new($_) } @$_ ] };

declare 'MapStringInstruction',
    as HashRef[Instruction()];

declare 'CsvInstruction',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Instruction::CsvInstruction'];

coerce 'CsvInstruction',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Instruction::CsvInstruction'->new($_) };

declare 'RepeatedCsvInstruction',
    as ArrayRef[CsvInstruction()];

coerce 'RepeatedCsvInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Instruction::CsvInstruction'->new($_) } @$_ ] };

declare 'MapStringCsvInstruction',
    as HashRef[CsvInstruction()];

declare 'PdfInstruction',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Instruction::PdfInstruction'];

coerce 'PdfInstruction',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Instruction::PdfInstruction'->new($_) };

declare 'RepeatedPdfInstruction',
    as ArrayRef[PdfInstruction()];

coerce 'RepeatedPdfInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Instruction::PdfInstruction'->new($_) } @$_ ] };

declare 'MapStringPdfInstruction',
    as HashRef[PdfInstruction()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Instruction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
