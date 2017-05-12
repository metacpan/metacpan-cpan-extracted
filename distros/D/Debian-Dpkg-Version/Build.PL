use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Debian::Dpkg::Version',
    license           => 'gpl',
    dist_version_from => 'lib/Debian/Dpkg/Version.pm',
    
    build_requires => {
        'Test::More'             => 0,
    },
    requires => {
        'Carp'                   => 0,
    },
    script_files => [
    ],
    add_to_cleanup => [ 'Debian-Dpkg-Version-*' ],
    create_readme  => 1,
    sign           => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Debian-Dpkg-Version.git',
            bugtracker => 'http://github.com/jozef/Debian-Dpkg-Version/issues',
        },
        keywords => [ qw/ debian perl versions / ],
    },
);

$builder->create_build_script();
