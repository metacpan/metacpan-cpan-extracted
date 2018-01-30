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
    META_MERGE => { 'LWP::Protocol::https' => 0, },
    PREREQ_PM  => {
        'Convert::PEM'           => 0,
        'Crypt::OpenSSL::RSA'    => 0,
        'HTML::Template'         => 0,
        'JSON'                   => 0,
        'Lemonldap::NG::Common'  => '1.9.15',
        'Lemonldap::NG::Handler' => '1.9.15',
        'LWP'                    => 0,
        'URI'                    => 0,
        'XML::LibXSLT'           => 0,
        'XML::LibXML'            => 0,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Manager.pm',    # retrieve abstract from module
            AUTHOR => 'Xavier Guimard <x.guimard@free.fr>'
              . ', Clément Oudot <clement@oodo.net>'
              . ', Thomas Chemineau <thomas.chemineau@gmail.com>'
          )
        : ()
    ),
    clean => {
        FILES => 't/conf/lmConf-2.js',
    },
);

