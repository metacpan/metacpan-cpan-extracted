use 5.014;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::top_targets {
    my $self = shift;
    my $r    = $self->MM::top_targets(@_);
    if ( my $cf = $ENV{LMNGCONFFILE} ) {
        $r =~ s/^(all.*)$/$1 my_target/m;
        $cf = quotemeta($cf);
        $r .= <<"EOT";

my_target:
	perl -i -pe 's/^(use constant DEFAULTCONFFILE\\s*=>).*\$\$/\$\$1 "$cf";/' blib/lib/Lemonldap/NG/Common/Conf/Constants.pm
EOT
    }
    return $r;
}

WriteMakefile(
    NAME           => 'Lemonldap::NG::Common',
    VERSION_FROM   => 'lib/Lemonldap/NG/Common.pm',    # finds $VERSION
    LICENSE        => 'gpl',
    BUILD_REQUIRES => {
        'IO::String' => 0,
        'Net::LDAP'  => 0,
        'Test::Pod'  => 1.00,
    },
    META_MERGE => {
        'recommends' => {
            'Apache::Session::Browseable' => 0,
            'Convert::Base32'             => 0,
            'Cookie::Baker::XS'           => 0,
            'Crypt::URandom'              => 0,
            'String::Random'              => 0,
            'DBI'                         => 0,
            'Net::LDAP'                   => 0,
            'SOAP::Lite'                  => 0,
            'LWP::Protocol::https'        => 0,
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
        'Apache::Session'        => 0,
        'Cache::Cache'           => 0,
        'Config::IniFiles'       => 0,
        'Crypt::OpenSSL::Bignum' => 0,
        'Crypt::OpenSSL::RSA'    => 0,
        'Crypt::OpenSSL::X509'   => 0,
        'Crypt::Rijndael'        => 0,
        'Crypt::URandom'         => 0,
        'Digest::SHA'            => 0,
        'HTML::Template'         => 0,
        'JSON'                   => 0,
        'Mouse'                  => 0,
        'Plack'                  => 0,
        'Test::Pod'              => 1.00,
        'URI'                    => 0,
    },    # e.g., Module::Name => 1.1
          #EXE_FILES => [ 'scripts/convertConfig', ],
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Common.pm',    # retrieve abstract from module
            AUTHOR =>
'Xavier Guimard <x.guimard@free.fr>, Clément Oudot <clement@oodo.net>'
          )
        : ()
    ),
    clean => {
        FILES => 't/lmConf*'
    },
    MAN1PODS => {
        'scripts/convertConfig'    => 'blib/man1/convertConfig.1p',
        'scripts/lemonldap-ng-cli' => 'blib/man1/lemonldap-ng-cli.1p',
    },
);
