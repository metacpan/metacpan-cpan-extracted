use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'Kasago',
  requires           => {
    'Class::Accessor::Chained::Fast' => '0',
    'DBD::Pg'                        => '0',
    'DBI'                            => '0',
    'File::Find::Rule'               => '0',
    'File::stat'                     => '0',
    'File::Slurp'                    => '0',
    'PPI'                            => '0',
    'Path::Class'                    => '0',
    'Test::More'                     => '0',
  },
);
$build->create_build_script;
