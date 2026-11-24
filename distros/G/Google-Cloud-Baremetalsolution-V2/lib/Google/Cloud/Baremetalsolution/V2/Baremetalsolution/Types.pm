package Google::Cloud::Baremetalsolution::V2::Baremetalsolution::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Baremetalsolution::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Baremetalsolution::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Baremetalsolution::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ResetInstanceResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Baremetalsolution::ResetInstanceResponse'];

coerce 'ResetInstanceResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Baremetalsolution::ResetInstanceResponse'->new($_) };

declare 'RepeatedResetInstanceResponse',
    as ArrayRef[ResetInstanceResponse()];

coerce 'RepeatedResetInstanceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Baremetalsolution::ResetInstanceResponse'->new($_) } @$_ ] };

declare 'MapStringResetInstanceResponse',
    as HashRef[ResetInstanceResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Baremetalsolution::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
