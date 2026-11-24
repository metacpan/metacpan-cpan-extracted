package Google::Cloud::Support::V2::Case::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Case',
    as InstanceOf['Google::Cloud::Support::V2::Case::Case'];

coerce 'Case',
    from HashRef, via { 'Google::Cloud::Support::V2::Case::Case'->new($_) };

declare 'RepeatedCase',
    as ArrayRef[Case()];

coerce 'RepeatedCase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::Case::Case'->new($_) } @$_ ] };

declare 'MapStringCase',
    as HashRef[Case()];

declare 'State',
    as (Int | Str);

declare 'Priority',
    as (Int | Str);

declare 'CaseClassification',
    as InstanceOf['Google::Cloud::Support::V2::Case::CaseClassification'];

coerce 'CaseClassification',
    from HashRef, via { 'Google::Cloud::Support::V2::Case::CaseClassification'->new($_) };

declare 'RepeatedCaseClassification',
    as ArrayRef[CaseClassification()];

coerce 'RepeatedCaseClassification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::Case::CaseClassification'->new($_) } @$_ ] };

declare 'MapStringCaseClassification',
    as HashRef[CaseClassification()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2::Case::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
