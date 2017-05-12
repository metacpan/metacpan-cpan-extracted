use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Emacs::Run',
    license             => 'perl',
    dist_author         => q{Joseph Brenner <doom@kzsu.stanford.edu>},
    dist_version_from   => 'lib/Emacs/Run.pm',
    build_requires      => {
                                 'Test::More'          => 0,
                                 'Class::Base'         => 0.03,
                                 'Data::Dumper'        => 0,
                                 'File::Spec'          => 0,
                                 'File::Basename'      => 0,
                                 'File::Copy'          => 0,
                                 'File::Temp'          => 0,
                                 'Hash::Util'          => 0,
                                 'List::MoreUtils'     => 0,
                                 'List::Util'          => 0,
                                 'Test::Differences'   => 0,
                                 'lib'                 => 0,
                                 'base'                => 0,
                                 'strict'              => 0,
                                 'warnings'            => 0,
                                 },
    add_to_cleanup      => [ 'Emacs-Run-*' ],
    create_makefile_pl => 'traditional',
);

# No longer in use:
###                                 'IPC::Capture'        => 0,

$builder->create_build_script();
