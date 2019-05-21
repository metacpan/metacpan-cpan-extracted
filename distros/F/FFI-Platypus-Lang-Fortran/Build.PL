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
    'FFI::Platypus'      => '0.22',
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
    'FFI::Build'    => '0.04',
  },
  requires => {
    'perl'          => '5.008001',
    'FFI::Platypus' => '0.51',
    'File::Which'   => 0,
    'Module::Build::FFI' => '0.22',
    'FFI::Build'    => '0.04',
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/Perl5-FFI/FFI-Platypus-Lang-Fortran",
      bugtracker => "http://github.com/Perl5-FFI/FFI-Platypus-Lang-Fortran/issues",
      x_IRC => "irc://irc.perl.org/#native",
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
  t/ffi/*.o
  t/ffi/*.obj
  t/ffi/*.so
  t/ffi/*.dylib
  t/ffi/*.bundle
  t/ffi/90/*.o
  t/ffi/90/*.obj
  t/ffi/90/*.so
  t/ffi/90/*.dylib
  t/ffi/90/*.bundle
  t/ffi/95/*.o
  t/ffi/95/*.obj
  t/ffi/95/*.so
  t/ffi/95/*.dylib
  t/ffi/95/*.bundle
  FFI-Platypus-Lang-Fortran-*
  config.log
));

$builder->create_build_script;
