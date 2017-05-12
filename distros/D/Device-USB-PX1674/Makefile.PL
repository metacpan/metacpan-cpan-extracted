use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Device::USB::PX1674',
    VERSION_FROM => 'lib/Device/USB/PX1674.pm', # finds $VERSION
    PREREQ_PM    => {},
    AUTHOR       => 'pilgrim@rolfrost.de',
);

CONFIGURE_REQUIRES => {
    'Inline::MakeMaker'   => 0.45,
    'ExtUtils::MakeMaker' => 6.52
};