use 5.014;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Lemonldap::NG::Manager',
    VERSION_FROM   => 'lib/Lemonldap/NG/Manager.pm',    # finds $VERSION
    LICENSE        => 'gpl',
    BUILD_REQUIRES => {
        'IO::String'     => 0,
        'Regexp::Common' => 0,
        'Test::Pod'      => 1.00,
    },
    META_MERGE => {
        recommends => {
            'LWP::Protocol::https' => 0,
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
        'Convert::PEM'           => 0,
        'Crypt::OpenSSL::RSA'    => 0,
        'Lemonldap::NG::Common'  => '2.0.5',
        'Lemonldap::NG::Handler' => '2.0.5',
        'LWP::UserAgent'         => 0,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Manager.pm',    # retrieve abstract from module
            AUTHOR =>
'Xavier Guimard <x.guimard@free.fr>, Clément Oudot <clement@oodo.net>'
          )
        : ()
    ),
    clean => {
        FILES => 't/conf/lmConf-2.json',
    },
);

