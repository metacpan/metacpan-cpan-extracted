#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { 
    unshift @INC => qw(test_lib t/test_lib);
    use_ok('Devel::StrictObjectHash', (
                        strict_bless => [ 'TestDerivedInitializer' ], 
                        allow_autovivification_in => qr/_init/
                        ));
}

# -----------------------------------------------------------------------------
# This test demostrates the following things:
# -----------------------------------------------------------------------------
# 	- the 'strict_bless' applied on the TestDerivedInitializer class
# 	- the 'allow_autovivification_in' applied with reg-ex
# Which we then test the expected behavior in TestDerivedInitializer 
# (and its parent class TestInitializer)
# 	- TestInitializer can create fields in '_init' routine
# 	- TestDerivedInitializer can create fields in 'new' and '_init' routine
# 	  and call TestInitializer '_init' as well to get those fields.
# -----------------------------------------------------------------------------

use TestDerivedInitializer;

my $test_derived_init;
eval {
    $test_derived_init = TestDerivedInitializer->new();
};
ok(!$@, '... this should not die');
diag("\n$@\n") if $@;

isa_ok($test_derived_init, 'TestDerivedInitializer');
isa_ok($test_derived_init, 'TestInitializer');

# I do not check the details of accessing the fields in this class, I probably should
# but the fact is that I know that stuff works from the other test, so in a way it is
# just redundant paranoia

