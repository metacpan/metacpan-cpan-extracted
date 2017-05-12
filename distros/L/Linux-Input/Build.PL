use Module::Build;

my $builder = Module::Build->new (
  module_name                  => 'Linux::Input',
  license                      => 'perl',

  requires                     => {
    'Class::Data::Inheritable' => 0,
    'IO::File'                 => 0,
    'IO::Select'               => 0,
  },

  build_requires               => {
    'Test::More'               => 0,
  },
  script_files                 => [
    'bin/evtest.pl'
  ],
  create_makefile_pl           => 'passthrough',
);

$builder->create_build_script();

# vim:sw=2 sts=2 expandtab
# $Id: Build.PL,v 1.2 2004/10/13 07:34:40 beppu Exp $
