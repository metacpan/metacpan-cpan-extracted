use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::All::SFTP',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version_from   => 'lib/IO/All/SFTP.pm',
    build_requires => {
        'Test::More' => 0,
        'LWP::Protocol::sftp' => 0,
        'IO::All::LWP' => 0,
    },
    requires => {
        'LWP::Protocol::sftp' => 0,
        'IO::All::LWP' => 0,
    },
    add_to_cleanup      => [ 'IO-All-SFTP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
