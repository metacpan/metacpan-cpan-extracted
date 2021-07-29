#!/usr/bin/perl

use v5;
use strict;
use warnings;

use Test::More;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

# default configuration
{
   my $build = $cc->new_module_build( module_name => "ExtUtils::CChecker" );

   isa_ok( $build, "Module::Build", '$build' );

   is( $build->module_name, "ExtUtils::CChecker", '$build->module_name in default config' );
}

$cc->push_include_dirs( "/usr/include/foo" );
$cc->push_extra_compiler_flags( "-DHAVE_FOO" );
$cc->push_extra_linker_flags( "-lfoo" );

# stored configuration
{
   my $build = $cc->new_module_build( module_name => "ExtUtils::CChecker" );

   is_deeply( $build->include_dirs,         [ "/usr/include/foo" ],
      '$build->include_dirs' );
   is_deeply( $build->extra_compiler_flags, [ "-DHAVE_FOO" ],
      '$build->extra_compiler_flags' );
   is_deeply( $build->extra_linker_flags,   [ "-lfoo" ],
      '$build->extra_linker_flags' );
}

# merged configuration
{
   my $build = $cc->new_module_build( 
      module_name => "ExtUtils::CChecker",
      include_dirs => [ "/usr/include/bar" ],
      extra_compiler_flags => [ "-DHAVE_BAR" ],
      extra_linker_flags => [ "-lbar" ],
   );

   is_deeply( $build->include_dirs,         [ "/usr/include/foo", "/usr/include/bar" ],
      '$build->include_dirs merged ');
   is_deeply( $build->extra_compiler_flags, [ "-DHAVE_FOO", "-DHAVE_BAR" ],
      '$build->extra_compiler_flags merged' );
   is_deeply( $build->extra_linker_flags,   [ "-lfoo", "-lbar" ],
      '$build->extra_linker_flags merged' );
}

done_testing;
