#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 44;

BEGIN { 
    unshift @INC => qw(test_lib t/test_lib);
    use_ok('Devel::StrictObjectHash', (
                            strict_bless => qr/Test.*?/, 
                            ));
}

# -----------------------------------------------------------------------------
# This test demostrates the following things:
# -----------------------------------------------------------------------------
# 	- the 'strict_bless' applied on the TestBase and TestDerived classes
# Which we then test the expected behavior in TestDerived
# 	- that no hash keys are accessable outside of TestDerived
# 	- private access is mediated through inherited TestBase methods
# 	- protected access is mediated through inherited TestBase methods
# 	- protected fields of TestBase are mediated through TestDerived methods
# 	- private fields of TestBase are not accessible from within TestDerived
# 	- private fields of TestDerived are mediated through TestDerived methods
# -----------------------------------------------------------------------------

use TestDerived;

can_ok("TestDerived", 'new');
my $test_derived = TestDerived->new();

isa_ok($test_derived, 'TestDerived');
isa_ok($test_derived, 'TestBase');

eval {
    $test_derived->{protected} = "Fail";
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for accessing protected outside the object');
} else {
    fail('... this should throw an exception');
}

eval {
    $test_derived->{_private} = "Fail";
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for accessing private outside the object');
} else {
    fail('... this should throw an exception');
}

eval {
    $test_derived->{_derived_private} = "Fail";
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for accessing derived private outside the object')
} else {
    fail('... this should throw an exception');
}

# test illegal accessing the private from TestBase 

eval {
    $test_derived->getPrivateFromBase()
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for attempting to access private from TestBase')
} else {
    fail('... this should throw an exception');
}

# NOTE:
# when running this test with debug on, lives_ok messes with the
# call stack somehow/somewhere, so it will report weird results.

# test new private in TestDerived

can_ok($test_derived, 'getPrivateForDerived');
can_ok($test_derived, 'setPrivateForDerived');

{
    my $private;
    eval {
        $private = $test_derived->getPrivateForDerived();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... derived private should be defined');
    is($private, 'derived private test', '... this should be equal');
    
    eval {
        $test_derived->setPrivateForDerived("derived private test (new)");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $private = $test_derived->getPrivateForDerived();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... derived private should be defined');
    is($private, 'derived private test (new)', '... this should be equal');
}

# test protected through in TestDerived

can_ok($test_derived, 'getDerivedProtected');
can_ok($test_derived, 'setDerivedProtected');

{
    my $protected;
    eval {
        $protected = $test_derived->getDerivedProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test', '... this should be equal');
    
    eval {
        $test_derived->setDerivedProtected("protected test (new)");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $protected = $test_derived->getDerivedProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test (new)', '... this should be equal');
}

# -----------------------------------------------------------------------------
# testing the method inherited from TestBase
# -----------------------------------------------------------------------------

# test private in TestBase

can_ok($test_derived, 'getPrivate');
can_ok($test_derived, 'setPrivate');

{
    my $private;
    eval {
        $private = $test_derived->getPrivate();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... private should be defined');
    is($private, 'private test', '... this should be equal');
    
    eval {
        $test_derived->setPrivate("private test (new)");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $private = $test_derived->getPrivate();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... private should be defined');
    is($private, 'private test (new)', '... this should be equal');
}

# test protected in TestBase

can_ok($test_derived, 'getProtected');
can_ok($test_derived, 'setProtected');

{
    my $protected;
    eval {
        $protected = $test_derived->getProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test (new)', '... this should be equal');
    
    eval {
        $test_derived->setProtected("protected test (new) again");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $protected = $test_derived->getProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test (new) again', '... this should be equal');
}
