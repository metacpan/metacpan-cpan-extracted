use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME              => 'Device::Modbus',
    VERSION_FROM      => 'lib/Device/Modbus.pm',
    PREREQ_PM         => {
		'Try::Tiny'        => 0.22,
	},
    ABSTRACT_FROM     => 'lib/Device/Modbus.pm',
    AUTHOR            => 'Julio Fraire <julio.fraire@gmail.com>',
    LICENSE           => 'artistic_2',
    META_MERGE        => {
		'meta-spec' => {
			version	=> 2,
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/jfraire/Device-Modbus.git',
				web  => 'https://github.com/jfraire/Device-Modbus',
			},
		},
	},
);
