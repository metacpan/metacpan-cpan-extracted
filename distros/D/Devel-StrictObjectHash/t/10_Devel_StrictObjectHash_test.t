#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;

BEGIN { 
    unshift @INC => qw(test_lib t/test_lib);
    use_ok('Devel::StrictObjectHash', (
                            strict_bless => [ qw(TestBase) ]
                            ));
}

# -----------------------------------------------------------------------------
# This test demostrates the following things:
# -----------------------------------------------------------------------------
# 	- the 'strict_bless' applied on the TestBase class
# Which we then test the expected behavior in TestBase
# 	- that no hash keys are accessable outside of TestBase
# 	- private access if mediated through TestBase methods
# 	- protected access is mediated through TestBase methods
# -----------------------------------------------------------------------------

use TestBase;

can_ok("TestBase", 'new');
my $test_base = TestBase->new();
isa_ok($test_base, 'TestBase');

eval {
    $test_base->{protected} = "Fail";
};
like($@, qr/Illegal Operation/, "... this should thrown an exception");

eval {
    $test_base->{_private} = "Fail";
};
like($@, qr/Illegal Operation/, "... this should thrown an exception");

# NOTE:
# when running this test with debug on, lives_ok messes with the
# call stack somehow/somewhere, so it will report weird results.

# test private in TestBase

can_ok($test_base, 'getPrivate');
can_ok($test_base, 'setPrivate');

my $private;
eval {
    $private = $test_base->getPrivate();
};
ok(!$@, "... this should not die");
diag("\n$@\n") if $@;
ok($private, '... private should be defined');
is($private, 'private test', '... this should be equal');

eval {
    $test_base->setPrivate("private test (new)");
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;

eval {
    $private = $test_base->getPrivate();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;
ok($private, '... private should be defined');
is($private, 'private test (new)', '... this should be equal');

# test protected in TestBase

can_ok($test_base, 'getProtected');
can_ok($test_base, 'setProtected');

my $protected;
eval {
    $protected = $test_base->getProtected();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;
ok($protected, '... protected should be defined');
is($protected, 'protected test', '... this should be equal');

eval {
    $test_base->setProtected("protected test (new)");
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;

eval {
    $protected = $test_base->getProtected();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;
ok($protected, '... protected should be defined');
is($protected, 'protected test (new)', '... this should be equal');


