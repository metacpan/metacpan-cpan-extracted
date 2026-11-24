package Google::Devtools::Resultstore::V2::FileProcessingError::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FileProcessingErrorType',
    as (Int | Str);

declare 'FileProcessingErrors',
    as InstanceOf['Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors'];

coerce 'FileProcessingErrors',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors'->new($_) };

declare 'RepeatedFileProcessingErrors',
    as ArrayRef[FileProcessingErrors()];

coerce 'RepeatedFileProcessingErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors'->new($_) } @$_ ] };

declare 'MapStringFileProcessingErrors',
    as HashRef[FileProcessingErrors()];

declare 'FileProcessingError',
    as InstanceOf['Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingError'];

coerce 'FileProcessingError',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingError'->new($_) };

declare 'RepeatedFileProcessingError',
    as ArrayRef[FileProcessingError()];

coerce 'RepeatedFileProcessingError',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingError'->new($_) } @$_ ] };

declare 'MapStringFileProcessingError',
    as HashRef[FileProcessingError()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::FileProcessingError::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
