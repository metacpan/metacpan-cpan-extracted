use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME              => 'Device::Modbus::RTU',
    VERSION_FROM      => 'lib/Device/Modbus/RTU.pm',
    PREREQ_PM         => {
		'Device::Modbus'     => 0.02,
		'Role::Tiny'         => 2.0,
		'Device::SerialPort' => 1.04,
	},
    ABSTRACT_FROM     => 'lib/Device/Modbus/RTU.pm',
    AUTHOR            => 'Julio Fraire <julio.fraire@gmail.com>',
    LICENSE           => 'artistic_2',
    META_MERGE        => {
		'meta-spec' => {
			version	=> 2,
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/jfraire/Device-Modbus-RTU.git',
				web  => 'https://github.com/jfraire/Device-Modbus-RTU',
			},
		},
	},
);
