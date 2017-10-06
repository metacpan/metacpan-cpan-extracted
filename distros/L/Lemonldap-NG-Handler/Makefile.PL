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
        'HTTP::Message'     => 0,
        'IO::Pipe'          => 0,
        'SOAP::Lite'        => 0,
        'Test::MockObject'  => 0,
        'Test::Pod'         => 0,
        'File::Basename'    => 0,
        'Cwd'               => 0,
    },
    META_MERGE => {
        'recommends' => {
            'Cache::Memcached'     => 0,
            'Digest::HMAC_SHA1'    => 0,
            'HTTP::Message'        => 0,
            'LWP::Protocol::https' => 0,
            'SOAP::Lite'           => 0,
        },
    },
    PREREQ_PM => {
        'Apache::Session::Generate::MD5' => 0,
        'CGI'                            => 3.08,
        'Lemonldap::NG::Common'          => '1.9.13',
        'LWP'                            => 0,
        'Mouse'                          => 0,
        'URI'                            => 0,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Handler.pm',    # retrieve abstract from module
            AUTHOR => 'Xavier Guimard <x.guimard@free.fr>'
          )
        : ()
    ),
);
