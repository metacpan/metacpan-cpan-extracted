use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::USB::PCSensor::HidTEMPer',
    VERSION_FROM      => 'lib/Device/USB/PCSensor/HidTEMPer.pm',
    PREREQ_PM         => {
        'Device::USB'           => "0.31",
        'Device::USB::Device'   => "0.29",
        'Time::HiRes'           => 0,
        'Carp'                  => 0,
    },
    AUTHOR            => 'Magnus Sulland <msulland@cpan.org>',
    LICENSE           => 'perl',
    ABSTRACT          => 'Interface to the PCSensor HidTEMPer thermometers series.',
    test              => {TESTS => 't/*.t'},
);
