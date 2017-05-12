use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME              => 'Device::Modbus::TCP',
    VERSION_FROM      => 'lib/Device/Modbus/TCP.pm',
    PREREQ_PM         => {
		'Device::Modbus'     => 0.021,
		'Try::Tiny'          => 0.22,
		'Role::Tiny'         => 2.0,
		'Net::Server'        => 2.008,
	},
	BUILD_REQUIRES    => {
	},
    ABSTRACT_FROM     => 'lib/Device/Modbus/TCP.pm',
    AUTHOR            => 'Julio Fraire <julio.fraire@gmail.com>',
    LICENSE           => 'artistic_2',
    META_MERGE        => {
		'meta-spec' => {
			version	=> 2,
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/jfraire/Device-Modbus-TCP.git',
				web  => 'https://github.com/jfraire/Device-Modbus-TCP',
			},
		},
	},
);
