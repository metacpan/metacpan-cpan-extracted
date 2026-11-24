package Google::Devtools::Resultstore::V2::TestSuite::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TestSuite',
    as InstanceOf['Google::Devtools::Resultstore::V2::TestSuite::TestSuite'];

coerce 'TestSuite',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::TestSuite::TestSuite'->new($_) };

declare 'RepeatedTestSuite',
    as ArrayRef[TestSuite()];

coerce 'RepeatedTestSuite',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::TestSuite::TestSuite'->new($_) } @$_ ] };

declare 'MapStringTestSuite',
    as HashRef[TestSuite()];

declare 'Test',
    as InstanceOf['Google::Devtools::Resultstore::V2::TestSuite::Test'];

coerce 'Test',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::TestSuite::Test'->new($_) };

declare 'RepeatedTest',
    as ArrayRef[Test()];

coerce 'RepeatedTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::TestSuite::Test'->new($_) } @$_ ] };

declare 'MapStringTest',
    as HashRef[Test()];

declare 'TestCase',
    as InstanceOf['Google::Devtools::Resultstore::V2::TestSuite::TestCase'];

coerce 'TestCase',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::TestSuite::TestCase'->new($_) };

declare 'RepeatedTestCase',
    as ArrayRef[TestCase()];

coerce 'RepeatedTestCase',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::TestSuite::TestCase'->new($_) } @$_ ] };

declare 'MapStringTestCase',
    as HashRef[TestCase()];

declare 'Result',
    as (Int | Str);

declare 'TestFailure',
    as InstanceOf['Google::Devtools::Resultstore::V2::TestSuite::TestFailure'];

coerce 'TestFailure',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::TestSuite::TestFailure'->new($_) };

declare 'RepeatedTestFailure',
    as ArrayRef[TestFailure()];

coerce 'RepeatedTestFailure',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::TestSuite::TestFailure'->new($_) } @$_ ] };

declare 'MapStringTestFailure',
    as HashRef[TestFailure()];

declare 'TestError',
    as InstanceOf['Google::Devtools::Resultstore::V2::TestSuite::TestError'];

coerce 'TestError',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::TestSuite::TestError'->new($_) };

declare 'RepeatedTestError',
    as ArrayRef[TestError()];

coerce 'RepeatedTestError',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::TestSuite::TestError'->new($_) } @$_ ] };

declare 'MapStringTestError',
    as HashRef[TestError()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::TestSuite::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
