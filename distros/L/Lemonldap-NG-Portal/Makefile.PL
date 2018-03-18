use 5.014;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Lemonldap::NG::Portal',
    VERSION_FROM => 'lib/Lemonldap/NG/Portal.pm',
    LICENSE      => 'gpl',
    META_MERGE   => {
        'recommends' => {
            'AuthCAS'                => 0,
            'DBI'                    => 0,
            'Glib'                   => 0,
            'HTTP::Message'          => 0,
            'JSON'                   => 0,
            'Lasso'                  => '2.3.0',
            'Lemonldap::NG::Handler' => '1.9.16',
            'LWP'                    => 0,
            'LWP::Protocol::https'   => 0,
            'MIME::Lite'             => 0,
            'Net::OAuth'             => 0,
            'Net::Facebook::Oauth2'  => 0,
            'Net::OpenID::Consumer'  => 0,
            'Net::OpenID::Server'    => 0,
            'SOAP::Lite'             => 0,
            'String::Random'         => 0,
            'URI'                    => 0,
            'Web::ID'                => 0,
            'XML::LibXSLT'           => 0,
            'XML::LibXML'            => 0,
            'XML::Simple'            => 0,
        },
    },
    BUILD_REQUIRES => {
        'AuthCAS'               => 0,
        'HTTP::Message'         => 0,
        'IO::String'            => 0,
        'LWP'                   => 0,
        'MIME::Lite'            => 0,
        'Net::OpenID::Consumer' => 0,
        'Net::OpenID::Server'   => 0,
        'SOAP::Lite'            => 0,
        'String::Random'        => 0,
        'Test::Pod'             => 1.00,
        'XML::LibXSLT'          => 0,
        'XML::LibXML'           => 0,
        'XML::Simple'           => 0,
    },
    PREREQ_PM => {
        'Authen::Captcha'       => 0,
        'CGI'                   => 3.08,
        'Clone'                 => 0,
        'HTML::Template'        => 0,
        'Lemonldap::NG::Common' => '1.9.16',
        'Net::LDAP'             => 0.38,
        'Regexp::Assemble'      => 0,
        'Unicode::String'       => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Portal.pm',    # retrieve abstract from module
            AUTHOR => 'Xavier Guimard <x.guimard@free.fr>'
              . ', Clément Oudot <clement@oodo.net>'
              . ', Thomas Chemineau <thomas.chemineau@gmail.com>'
              . ', Mikael Ates <mikael.ates@univ-st-etienne.fr>'
          )
        : ()
    ),
);
