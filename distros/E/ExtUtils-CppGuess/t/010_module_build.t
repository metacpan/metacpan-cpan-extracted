use strict;
use Test::More;
BEGIN {
  plan skip_all => 'no Module::Build' if !eval { require Module::Build; 1 };
}
use lib 't/lib';
use TestUtils;

my $separator = ( '=' x 40 . "\n" );

prepare_test( 't/module', 't/module_build' );
my( $ok, $configure, $build, $test ) = build_module_build( 't/module_build' );

ok( $ok, 'build with Module::Build' );
if( !$ok ) {
    diag( "Build.PL output\n",   $separator, $configure, $separator );
    diag( "Build output\n",      $separator, $build, $separator ) if $build;
    diag( "Build test output\n", $separator, $test, $separator ) if $test;
}

done_testing;
