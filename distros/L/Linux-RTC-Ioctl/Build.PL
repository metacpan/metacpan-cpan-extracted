use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Linux::RTC::Ioctl',
    license             => 'perl_5',
    dist_author         => q{Timothy Madden <terminatorul@gmail.com>},
    dist_version_from   => 'lib/Linux/RTC/Ioctl.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
	'Fcntl'	     => 0,
	'POSIX'	     => 0
    },
    requires => {
        'Carp'              => 0,
	'Cwd'		    => 0
    },
    add_to_cleanup     => [ 'Linux-RTC-Ioctl-*' ],
    create_makefile_pl => 'traditional',
    c_source	       => 'src',
    # extra_compiler_flags => '-g -O0'
);

$builder->create_build_script();
