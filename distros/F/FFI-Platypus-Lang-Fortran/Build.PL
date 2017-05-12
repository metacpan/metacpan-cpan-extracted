BEGIN {
  unless(eval q{ use 5.008001; 1 }) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}
use strict;
use warnings;
use lib 'inc';
use lib 'lib';
use My::ModuleBuild;

my $builder = My::ModuleBuild->new(
  module_name => 'FFI::Platypus::Lang::Fortran',
  dist_abstract => 'Documentation and tools for using Platypus with Fortran',
  dist_author => [ 'Graham Ollis <plicease@cpan.org>' ],
  license => 'perl',
  configure_requires => {
    'Module::Build'      => 0.38,
    'Module::Build::FFI' => '0.22',
    'File::Which'   => 0,
  },
  build_requires => {
    'Module::Build' => 0.38,
    'File::Which'   => 0,
    'Module::Build::FFI' => '0.22',
  },
  test_requires => {
    'FFI::CheckLib' => 0,
    'File::Which'   => 0,
    'Module::Build::FFI' => '0.22',
  },
  requires => {
    'perl'          => '5.008001',
    'FFI::Platypus' => '0.22',
    'File::Which'   => 0,
    'Module::Build::FFI' => '0.22',
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/plicease/FFI-Platypus-Lang-Fortran",
      bugtracker => "http://github.com/plicease/FFI-Platypus-Lang-Fortran/issues",
    },
    no_index => {
      directory => [ 'examples' ],
    },
  },  
);

$builder->add_to_cleanup(qw(
  *.bak
  examples/*.o
  examples/*.obj
  examples/*.so
  examples/*.dylib
  examples/*.bundle
  libtest/*.o
  libtest/*.obj
  libtest/*.so
  libtest/*.dylib
  libtest/*.bundle
  libtest/90/*.o
  libtest/90/*.obj
  libtest/90/*.so
  libtest/90/*.dylib
  libtest/90/*.bundle
  libtest/95/*.o
  libtest/95/*.obj
  libtest/95/*.so
  libtest/95/*.dylib
  libtest/95/*.bundle
  FFI-Platypus-Lang-Fortran-*
  config.log
));

$builder->create_build_script;
