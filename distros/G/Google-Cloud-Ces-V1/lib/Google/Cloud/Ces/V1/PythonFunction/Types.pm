package Google::Cloud::Ces::V1::PythonFunction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PythonFunction',
    as InstanceOf['Google::Cloud::Ces::V1::PythonFunction::PythonFunction'];

coerce 'PythonFunction',
    from HashRef, via { 'Google::Cloud::Ces::V1::PythonFunction::PythonFunction'->new($_) };

declare 'RepeatedPythonFunction',
    as ArrayRef[PythonFunction()];

coerce 'RepeatedPythonFunction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::PythonFunction::PythonFunction'->new($_) } @$_ ] };

declare 'MapStringPythonFunction',
    as HashRef[PythonFunction()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::PythonFunction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
