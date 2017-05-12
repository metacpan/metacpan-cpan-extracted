use 5.022001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Log::Any::Adapter::Multiplexor',
    VERSION_FROM        => 'lib/Log/Any/Adapter/Multiplexor.pm', 
    PREREQ_PM           => {
                                'Log::Any'                  => 0,
                                'Log::Any::Adapter'         => 0,
                                'Log::Any::Adapter::Stdout' => 0,
                                                }, 
    ABSTRACT_FROM       => 'lib/Log/Any/Adapter/Multiplexor.pm', 
    AUTHOR              => 'Pavel Andryushin <vrag867@gmail.com>',
    LICENSE             => 'perl5',
    MIN_PERL_VERSION    => 5.008001,
    CONFIGURE_REQUIRES  => { 
                                'ExtUtils::MakeMaker' => 0,
                            },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => {
                web    => 'https://github.com/vrag86/Log-Any-Adapter-Multiplexor/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/vrag86/Log-Any-Adapter-Multiplexor.git',
                web  => 'https://github.com/vrag86/Log-Any-Adapter-Multiplexor',
            },
        },
    },
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
