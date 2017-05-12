#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

use ExtUtils::CChecker;

my $mbpackage;
my %mbargs;
my $mbret;

no warnings 'once';
local *Module::Build::new = sub {
   ( $mbpackage, %mbargs ) = @_;
   return $mbret;
};

my $cc = ExtUtils::CChecker->new;

$cc->new_module_build( module_name => "Foo::Bar" );

is( $mbpackage, "Module::Build", '$mbpackage after ->new_module_build' );
is_deeply( \%mbargs,
   {
      module_name => "Foo::Bar",
      include_dirs => [],
      extra_compiler_flags => [],
      extra_linker_flags => [],
   },
   '%mbargs after ->new_module_build' );

$cc->push_include_dirs( "/usr/include/foo" );
$cc->push_extra_compiler_flags( "-DHAVE_FOO" );
$cc->push_extra_linker_flags( "-lfoo" );

$cc->new_module_build( module_name => "Foo::Bar" );

is_deeply( \%mbargs,
   {
      module_name => "Foo::Bar",
      include_dirs => [ "/usr/include/foo" ],
      extra_compiler_flags => [ "-DHAVE_FOO" ],
      extra_linker_flags => [ "-lfoo" ],
   },
   '%mbargs sees correct dirs and flags' );

$cc->new_module_build( 
   module_name => "Foo::Bar",
   include_dirs => [ "/usr/include/bar" ],
   extra_compiler_flags => [ "-DHAVE_BAR" ],
   extra_linker_flags => [ "-lbar" ],
);

is_deeply( \%mbargs,
   {
      module_name => "Foo::Bar",
      include_dirs => [ "/usr/include/foo", "/usr/include/bar" ],
      extra_compiler_flags => [ "-DHAVE_FOO", "-DHAVE_BAR" ],
      extra_linker_flags => [ "-lfoo", "-lbar" ],
   },
   'new_module_build merges %args and internal configuration' );
