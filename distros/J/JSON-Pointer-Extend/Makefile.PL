use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'JSON::Pointer::Extend',
    VERSION_FROM        => 'lib/JSON/Pointer/Extend.pm',
    PREREQ_PM           => {
                                'Carp'                      => 0,
                                'JSON::Pointer'             => '0.07',
                            },
    ABSTRACT_FROM       => 'lib/JSON/Pointer/Extend.pm',
    AUTHOR              => 'Pavel Andryushin <vrag867@gmail.com>',
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => '5.12.1',
    CONFIGURE_REQUIRES  => {
                                'ExtUtils::MakeMaker' => 0,
                            },
    META_MERGE   => {
          requires  => { perl => '5.12.1' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/json-pointer-extend',
                bugtracker  => 'https://github.com/vrag86/json-pointer-extend/issues'
              },
        },
);
