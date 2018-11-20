use ExtUtils::MakeMaker;

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod';

WriteMakefile(
    NAME            => 'Device::Chip::ADT7470',
    VERSION_FROM    => 'lib/Device/Chip/ADT7470.pm',
    PREREQ_PM => {
        'Data::Bitfield'                    => '0.02',
	'Device::Chip'                      => '0.04',
        'Device::Chip::Base::RegisteredI2C' => '0.10',
	'Carp'                              => 0,
        'strict'                            => 0,
        'warnings'                          => 0,
    },
    TEST_REQUIRES => {
        'Test::Device::Chip::Adapter' => 0,
        'Test::More'                  => '0.88',    # done_testing
        'Test::Exception'             => '0.43',
    },
    dist                => {
	PREOP => $preop,
    },
    LICENSE  => 'perl_5',
    META_MERGE => {
        resources => {
	    license     => [ 'http://dev.perl.org/licenses/' ],
	    repository  => {
	        web  => 'https://github.com/john-/Device-Chip-ADT7470',
	    },
        },
    },
);
