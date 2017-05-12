use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Emacs::Rep',
    license             => 'perl',
    dist_author         => q{Joseph Brenner <doom@kzsu.stanford.edu>},
    dist_version_from   => 'lib/Emacs/Rep.pm',
    build_requires => {
        'Test::More'             => 0,
        'FindBin'                => 0,
        'lib'                    => 0,
        'Test::Trap'             => 0,
        'Test::Differences'      => 0,
      },
    requires => {
        'PPI'            => 0,
        'strict'         => 0,
        'warnings'       => 0,
        'Carp'           => 0,
        'Data::Dumper'   => 0,
        'Exporter'       => 0,
      },
    add_to_cleanup      => [ 'Emacs-Rep-*' ],
    create_makefile_pl => 'traditional',
    script_files => ['script/rep.pl'],
);

$builder->create_build_script();
