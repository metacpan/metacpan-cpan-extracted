use 5.014;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Lemonldap::NG::Handler',
    VERSION_FROM   => 'lib/Lemonldap/NG/Handler.pm',
    LICENSE        => 'gpl',
    PMLIBDIRS      => ['lib'],
    BUILD_REQUIRES => {
        'Digest::HMAC_SHA1' => 0,
        'IO::Pipe'          => 0,
        'Test::MockObject'  => 0,
        'Test::Pod'         => 0,
        'Cwd'               => 0,
    },
    META_MERGE => {
        'recommends' => {
            'Cache::Memcached'  => 0,
            'Digest::HMAC_SHA1' => 0,
            'HTTP::Message'     => 0,
            'SOAP::Lite'        => 0,
        },
        resources => {
            repository => {
                url  => 'https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng.git',
                web  => 'https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng',
                type => 'git',
            },
            MailingList => 'mailto:lemonldap-ng-dev@ow2.org',
            license     => 'http://opensource.org/licenses/GPL-2.0',
            homepage    => 'http://lemonldap-ng.org/',
            bugtracker  => {
                web =>
                  'https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues',
            },
            x_twitter => 'https://twitter.com/lemonldapng',
        },
    },
    PREREQ_PM => {
        'Lemonldap::NG::Common' => '2.0.5',
        'LWP::UserAgent'        => 0,
        'Mouse'                 => 0,
        'URI'                   => 0,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Handler.pm',    # retrieve abstract from module
            AUTHOR =>
'Xavier Guimard <x.guimard@free.fr>, Clément Oudot <clement@oodo.net>'
          )
        : ()
    ),
);
