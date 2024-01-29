use ExtUtils::MakeMaker;

WriteMakefile(
    NAME    => 'GDPR::IAB::TCFv2',
    AUTHOR  => 'Tiago Peczenyj <tiago.peczenyj+gdpr-iab-tcfv2@gmail.com>',
    LICENSE => "perl_5",
    ABSTRACT_FROM    => 'lib/GDPR/IAB/TCFv2.pm',
    VERSION_FROM     => 'lib/GDPR/IAB/TCFv2.pm',
    MIN_PERL_VERSION => 5.008,
    TEST_REQUIRES    => {
        'Test::Exception' => 0.43,
        'Test::More'      => 0.94,
        'Test::Pod'       => 0,
    },
    (   eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ( META_MERGE => {
                'meta-spec'    => { version => 2 },
                dynamic_config => 0,
                resources      => {
                    homepage   => 'https://github.com/peczenyj/GDPR-IAB-TCFv2',
                    repository => {
                        type => 'git',
                        url  =>
                          'https://github.com/peczenyj/GDPR-IAB-TCFv2.git',
                        web => 'https://github.com/peczenyj/GDPR-IAB-TCFv2',
                    },
                    bugtracker => {
                        web =>
                          'https://github.com/peczenyj/GDPR-IAB-TCFv2/issues'
                    },
                },
                recommends => {
                    'JSON' => 0,
                },
                x_authority => 'cpan:PACMAN',
            }
          )
        : ()
    ),
);
