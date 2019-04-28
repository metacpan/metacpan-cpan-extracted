use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME             => 'Log::Dispatch::Email::Siffra',
    VERSION_FROM     => 'lib/Log/Dispatch/Email/Siffra.pm',
    ABSTRACT_FROM    => 'lib/Log/Dispatch/Email/Siffra.pm',
    AUTHOR           => 'Luiz Benevenuto (luiz@siffra.com.br)',
    MIN_PERL_VERSION => '5.014',
    LICENSE          => 'perl',
    INSTALLDIRS      => ( $] < 5.011 ? 'perl' : 'site' ),
    PREREQ_PM        => {

        # Default req
        'strict'       => 0,
        'warnings'     => 0,
        'Carp'         => 0,
        'utf8'         => 0,
        'Data::Dumper' => 0,
        'DDP'          => 0,
        'Log::Any'     => 0,
        'Scalar::Util' => 0,
        'version'      => 0,
        'Test::More'   => 0,
        # Default req

        'Encode'               => 0,
        'Log::Dispatch::Email' => 0,
        'MIME::Lite'           => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    (
        eval { ExtUtils::MakeMaker->VERSION( 6.46 ) }
        ? ()
        : (
            META_MERGE => {
                'meta-spec'    => { version => 2 },
                dynamic_config => 1,
                resources      => {
                    homepage   => 'https://siffra.com.br',
                    repository => {
                        url  => 'git@github.com:SiffraTI/Log-Dispatch-Email-Siffra.git',
                        web  => 'https://github.com/SiffraTI/Log-Dispatch-Email-Siffra',
                        type => 'git',
                    },
                    bugtracker => {
                        web => 'https://github.com/SiffraTI/Log-Dispatch-Email-Siffra/issues',
                    },
                },
            }
        )
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Log-Dispatch-Email-Siffra-* *.old *.bak' },
);

WriteMakefile( %WriteMakefileArgs );
