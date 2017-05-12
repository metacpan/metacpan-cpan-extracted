use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Dir::Rocknroll',
    license             => 'perl',
    dist_author         => q{Jacquelin Charbonnel <jacquelin.charbonnel at math.cnrs.fr>},
    dist_version_from   => 'lib/Dir/Rocknroll.pm',
    build_requires => {
        'Test::More' => 0,
        'Sys::Syslog' => 0,
        'File::Path::Tiny' => 0,
        'Getopt::Long' => 0,
        'File::Basename' => 0,
        'FileHandle' => 0,
        'DirHandle' => 0,
        'FindBin' => 0,
        'Net::SMTP' => 0,
        'Sys::Hostname' => 0,
        'Config::General' => 0,
        'Config::General::Extended' => 0,
        'Dir::Which' => 0,
        'File::stat' => 0,
        'Pod::Perldoc' => 0
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Dir-Rocknroll-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
