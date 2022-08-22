use strict;
use warnings;

use Module::Build;

my @extra_compiler_flags = qw( -Iinclude -Ihax -ggdb );

# Perl 5.36 made -std=c99 standard; before then we'll have to request it specially
push @extra_compiler_flags, qw( -std=c99 ) if $^V lt v5.36.0;

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

# Author support for shared test file
if( -f( my $TESTSRC = "../Future/t/lib/FutureTests.pm" ) ) {
   system( "cp", $TESTSRC, "t/lib/" );
}

my $build = Module::Build->new(
   module_name => 'Future::XS',
   requires => {
      'perl' => '5.014',
   },
   test_requires => {
      'Test::Fatal' => 0,
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

if( eval { require Devel::MAT::Dumper::Helper and
            Devel::MAT::Dumper::Helper->VERSION( '0.44' ) } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

# cheating
$build->add_property( 'optimize' );
$build->config( optimize => '' );

$build->create_build_script;
