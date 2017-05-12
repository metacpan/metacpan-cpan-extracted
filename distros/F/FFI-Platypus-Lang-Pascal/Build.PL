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
use Env qw( @PATH );
use ExtUtils::CBuilder;
use File::Spec;
use File::Which qw( which );

unless(which('fpc'))
{
  print "Unable to find Free Pascal.  Please make sure it is in the PATH.\n";
  print "You should still be able to use pre-compiled Free Pascal dynamic libs.\n";
}

my $builder = My::ModuleBuild->new(
  module_name   => 'FFI::Platypus::Lang::Pascal',
  dist_abstract => 'Documentation and tools for using Platypus with the Free Pascal '.
                   'programming language',
  dist_author   => [ 'Graham Ollis <plicease@cpan.org>' ],
  license       => 'perl',
  configure_requires => {
    'Module::Build'      => 0.38,
    'ExtUtils::CBuilder' => 0,
    'Module::Build::FFI' => 0.19,
    'File::Which' => 0,
    'File::chdir' => 0,
  },
  build_requires => {
    'Module::Build'      => 0.38,
    'ExtUtils::CBuilder' => 0,
    'Module::Build::FFI' => 0.19,
    'File::Which' => 0,
    'File::chdir' => 0,
  },
  test_requires => {
    'FFI::CheckLib' => 0,
  },
  requires => {
    'perl',               => '5.008001',
    'FFI::Platypus'       => '0.19',
    'File::Which'         => 0,
    'File::chdir'         => 0,
    'FFI::ExtractSymbols' => 0,
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/plicease/FFI-Platypus-Lang-Pascal",
      bugtracker => "http://github.com/plicease/FFI-Platypus-Lang-Pascal/issues",
    },
    no_index => {
      directory => [ 'examples' ],
    },
  },
);

$builder->add_to_cleanup(
  '*.bak',
  '*.ppu',
  'examples/*.o',
  'examples/*.so',
  'examples/*.ppu',
  'examples/*.ppl',
  'libtest/*.o',
  'libtest/*.so',
  'libtest/*.ppu',
  'libtest/*.ppl',
  'FFI-Platypus-Lang-Pascal-*',
);

$builder->create_build_script;
