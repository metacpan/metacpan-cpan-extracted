use 5.008;
use ExtUtils::MakeMaker;

my %eumm_params = (
    NAME              => 'HeliosX::Logger::HiRes',
    VERSION_FROM      => 'lib/HeliosX/Logger/HiRes.pm', # finds $VERSION
    AUTHOR            => 'Andrew Johnson <lajandy at cpan dot org>',
    ABSTRACT_FROM     => 'lib/HeliosX/Logger/HiRes.pm',
    LICENSE           => 'artistic_2',
    PREREQ_PM         => {
                          'Helios'      => 2.80,
                          'Time::HiRes' => 1.86,
                          'Time::Piece' => 1.12,
                          'parent'      => 0.221,
                          'JSON::Tiny'  => 0.48,
                         }, 
    EXE_FILES         => ['heliosx_logger_hires_search'],
    INST_SCRIPT       => 'bin',
);

# meta
if (ExtUtils::MakeMaker->VERSION >= 6.46 ) {
    $eumm_params{META_MERGE} = {
        'meta-spec' => { version => 1.4 },
        resources => {
            repository => 'git://github.com/logicalhelion/heliosx-logger-hires.git',
        },
    };
}

# minimum Perl version
if (ExtUtils::MakeMaker->VERSION >= 6.48 ) {
    $eumm_params{MIN_PERL_VERSION} = 5.008;
}

# write that Makefile
WriteMakefile(%eumm_params);


