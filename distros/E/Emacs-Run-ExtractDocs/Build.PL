use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Emacs::Run::ExtractDocs',
    license             => 'perl',
    dist_author         => q{Joseph Brenner <doom@kzsu.stanford.edu>},
    dist_version_from   => 'lib/Emacs/Run/ExtractDocs.pm',
    build_requires => {
        'Test::More'  => 0,
        'File::Path'  => 0,
        'File::Copy'  => 0,
        'Fatal'       => 0,
        'Cwd'         => 0,
        'FindBin'     => 0,
        'lib'         => 0,
        'Date::Calc'  => 0,
        'Test::Differences' => 0,
    },
    requires => {
        'strict'         => 0,
        'warnings'       => 0,
        'Carp'           => 0,
        'Data::Dumper'   => 0,
        'Hash::Util'     => 0,
        'File::Basename' => 0,
        'Env'            => 0,
        'Emacs::Run'     => 0,
        'Class::Base'    => 0,
    },
    add_to_cleanup      => [ 'Emacs-Run-ExtractDocs-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
