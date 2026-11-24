package Google::Cloud::Talent::V4beta1::Company::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Company',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Company::Company'];

coerce 'Company',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Company::Company'->new($_) };

declare 'RepeatedCompany',
    as ArrayRef[Company()];

coerce 'RepeatedCompany',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Company::Company'->new($_) } @$_ ] };

declare 'MapStringCompany',
    as HashRef[Company()];

declare 'DerivedInfo',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Company::Company::DerivedInfo'];

coerce 'DerivedInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Company::Company::DerivedInfo'->new($_) };

declare 'RepeatedDerivedInfo',
    as ArrayRef[DerivedInfo()];

coerce 'RepeatedDerivedInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Company::Company::DerivedInfo'->new($_) } @$_ ] };

declare 'MapStringDerivedInfo',
    as HashRef[DerivedInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::Company::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
