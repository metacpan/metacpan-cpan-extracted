#!perl -T

use 5.008;

use strict;
use warnings;

use Test::More;

plan tests => 28;

use lib 't/lib';
use lib './lib';

# Use this sub to supply arguments to the assertions that are being stubbed
# out, so we can test whether the arguments are being evaluated or not:
#
sub foo { die "stub arguments got evaluated\n" }

my $package;

#----------------------------------------------------------

package ImportNothing;
$package = __PACKAGE__;

use MyAssertions;

eval { _assert_non_empty(''); };
Test::More::like($@, qr/^Undefined subroutine &${package}::_assert_non_empty /, "$package sub");

#----------------------------------------------------------

package ImportUnconditionally;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar );

eval { _assert_non_empty('') };
Test::More::is($@, "Found empty value\n", "$package sub (empty)");

eval { _assert_non_empty('foo') };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportIfTrue;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -if => 42;

eval { _assert_non_empty('') };
Test::More::is($@, "Found empty value\n", "$package sub (empty)");

eval { _assert_non_empty('foo') };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportIfTrueCoderef;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -if => sub { 42 };

eval { _assert_non_empty('') };
Test::More::is($@, "Found empty value\n", "$package sub (empty)");

eval { _assert_non_empty('foo') };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportIfFalse;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -if => 1 == 2;

eval { _assert_non_empty('') };
Test::More::is($@, '', "$package sub (empty)");

eval { _assert_non_empty( ::foo() ) };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportIfFalseCoderef;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -if => sub { 1 == 2 };

eval { _assert_non_empty('') };
Test::More::is($@, '', "$package sub (empty)");

eval { _assert_non_empty( ::foo() ) };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportUnlessFalse;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -unless => 1 == 2;

eval { _assert_non_empty('') };
Test::More::is($@, "Found empty value\n", "$package sub (empty)");

eval { _assert_non_empty('foo') };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportUnlessFalseCoderef;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -unless => sub { 1 == 2 };

eval { _assert_non_empty('') };
Test::More::is($@, "Found empty value\n", "$package sub (empty)");

eval { _assert_non_empty('foo') };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportUnlessTrue;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -unless => 42;

eval { _assert_non_empty('') };
Test::More::is($@, '', "$package sub (empty)");

eval { _assert_non_empty( ::foo() ) };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

#----------------------------------------------------------

package ImportUnlessTrueCoderef;
$package = __PACKAGE__;

use MyAssertions qw( _assert_non_empty $some_scalar ), -unless => sub { 42 };

eval { _assert_non_empty('') };
Test::More::is($@, '', "$package sub (empty)");

eval { _assert_non_empty( ::foo() ) };
Test::More::is($@, '', "$package sub (not empty)");

Test::More::is($some_scalar, 42, "$package scalar");

