#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 68;

BEGIN { 
    unshift @INC => qw(test_lib t/test_lib);
    
    use_ok('Devel::StrictObjectHash', (
                        strict_bless      => qr/Test(.*?)Identifier/, 
                        field_access_identifiers => {
                                public    => qr/^[a-z]*$/,
                                protected => qr/^_[a-z]*$/,
                                private   => qr/^__[A-Z]*?__$/
                                }
                        ));
}

# -----------------------------------------------------------------------------
# This test demostrates the following things:
# -----------------------------------------------------------------------------
# - the setting of the field access identifiers
# -----------------------------------------------------------------------------


use TestFieldIdentifier;

can_ok("TestFieldIdentifier", 'new');
my $test_fields = TestFieldIdentifier->new();
isa_ok($test_fields, 'TestFieldIdentifier');

is($test_fields->{public}, 'public test', '... testing the public functionality');

eval {
    $test_fields->{"_protected"} = "Fail";
};
like($@, qr/Illegal Operation/, "... this should thrown an exception");

eval {
    $test_fields->{"__PRIVATE__"} = "Fail";
};
like($@, qr/Illegal Operation/, "... this should thrown an exception");

# NOTE:
# when running this test with debug on, lives_ok messes with the
# call stack somehow/somewhere, so it will report weird results.

# test private in TestFieldIdentifier

can_ok($test_fields, 'getPrivate');
can_ok($test_fields, 'setPrivate');

my $private;
eval {
    $private = $test_fields->getPrivate();
};
ok(!$@, "... this should not die");
diag("\n$@\n") if $@;
ok($private, '... private should be defined');
is($private, 'private test', '... this should be equal');

eval {
    $test_fields->setPrivate("private test (new)");
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;

eval {
    $private = $test_fields->getPrivate();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;
ok($private, '... private should be defined');
is($private, 'private test (new)', '... this should be equal');

# test protected in TestFieldIdentifier

can_ok($test_fields, 'getProtected');
can_ok($test_fields, 'setProtected');

my $protected;
eval {
    $protected = $test_fields->getProtected();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;
ok($protected, '... protected should be defined');
is($protected, 'protected test', '... this should be equal');

eval {
    $test_fields->setProtected("protected test (new)");
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;

eval {
    $protected = $test_fields->getProtected();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;
ok($protected, '... protected should be defined');
is($protected, 'protected test (new)', '... this should be equal');

# test derived field identifier stuff

use TestDerivedFieldIdentifier;

can_ok("TestDerivedFieldIdentifier", 'new');
my $test_fields_derived = TestDerivedFieldIdentifier->new();

isa_ok($test_fields_derived, 'TestDerivedFieldIdentifier');
isa_ok($test_fields_derived, 'TestFieldIdentifier');

is($test_fields_derived->{public}, 'public test', '... testing the public functionality');

eval {
    $test_fields_derived->{"_protected"} = "Fail";
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for accessing protected outside the object');
} else {
    fail('... this should throw an exception');
}

eval {
    $test_fields_derived->{"__PRIVATE__"} = "Fail";
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for accessing private outside the object');
} else {
    fail('... this should throw an exception');
}

eval {
    $test_fields_derived->{"__DERIVED_PRIVATE__"} = "Fail";
};
if ($@) {
    like($@, qr/Illegal Operation/, 
         '... this should thrown an exception for accessing derived private outside the object')
} else {
    fail('... this should throw an exception');
}

# test illegal accessing the private from TestBase 

eval {
    $test_fields_derived->getPrivateFromBase()
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

can_ok($test_fields_derived, 'getPrivateForDerived');
can_ok($test_fields_derived, 'setPrivateForDerived');

{
    my $private;
    eval {
        $private = $test_fields_derived->getPrivateForDerived();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... derived private should be defined');
    is($private, 'derived private test', '... this should be equal');
    
    eval {
        $test_fields_derived->setPrivateForDerived("derived private test (new)");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $private = $test_fields_derived->getPrivateForDerived();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... derived private should be defined');
    is($private, 'derived private test (new)', '... this should be equal');
}

# test protected through in TestDerived

can_ok($test_fields_derived, 'getDerivedProtected');
can_ok($test_fields_derived, 'setDerivedProtected');

{
    my $protected;
    eval {
        $protected = $test_fields_derived->getDerivedProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test', '... this should be equal');
    
    eval {
        $test_fields_derived->setDerivedProtected("protected test (new)");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $protected = $test_fields_derived->getDerivedProtected();
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

can_ok($test_fields_derived, 'getPrivate');
can_ok($test_fields_derived, 'setPrivate');

{
    my $private;
    eval {
        $private = $test_fields_derived->getPrivate();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... private should be defined');
    is($private, 'private test', '... this should be equal');
    
    eval {
        $test_fields_derived->setPrivate("private test (new)");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $private = $test_fields_derived->getPrivate();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($private, '... private should be defined');
    is($private, 'private test (new)', '... this should be equal');
}

# test protected in TestBase

can_ok($test_fields_derived, 'getProtected');
can_ok($test_fields_derived, 'setProtected');

{
    my $protected;
    eval {
        $protected = $test_fields_derived->getProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test (new)', '... this should be equal');
    
    eval {
        $test_fields_derived->setProtected("protected test (new) again");
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    
    eval {
        $protected = $test_fields_derived->getProtected();
    };
    ok(!$@, '... this should not die');
    diag("\n$@\n") if $@;
    ok($protected, '... protected should be defined');
    is($protected, 'protected test (new) again', '... this should be equal');
}


