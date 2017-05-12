#!perl

use File::Spec;
use Module::Find;
use Test::Deep;
use Test::Roo;
use Test::MockTime;

use lib File::Spec->catdir( 't', 'lib' );
my @test_roles;

if ( $ENV{TEST_ROLE_ONLY} ) {
    push @test_roles, map { "Test::$_" } split(/,/, $ENV{TEST_ROLE_ONLY});
}
else {
    my @old_inc = @INC;
    setmoduledirs( File::Spec->catdir( 't', 'lib' ) );

    # Test::Fixtures is always run first
    @test_roles = sort grep { $_ ne 'Test::Fixtures' } findsubmod Test;
    unshift @test_roles, 'Test::Fixtures';

    setmoduledirs(@old_inc);
}

with 'Interchange6::Test::Role::Fixtures', 'Interchange6::Test::Role::SQLite', @test_roles;

run_me;

done_testing;
