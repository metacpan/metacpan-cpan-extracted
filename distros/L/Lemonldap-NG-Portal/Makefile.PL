use 5.014;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Autodiscover needed man1 files
opendir D, 'scripts' or die $!;
my $man1 = {};
while ( my $file = readdir D ) {
    next if $file =~ /^\./;
    open my $fh, '<', "scripts/$file" or die $!;
    while (<$fh>) {
        if (/^=head1/) {
            $man1->{"scripts/$file"} = "blib/man1/$file.1p";
            last;
        }
    }
}

WriteMakefile(
    NAME         => 'Lemonldap::NG::Portal',
    VERSION_FROM => 'lib/Lemonldap/NG/Portal.pm',
    LICENSE      => 'gpl',
    META_MERGE   => {
        'recommends' => {
            'Authen::Radius'              => 0,
            'Authen::WebAuthn'            => 0,
            'Convert::Base32'             => 0,
            'HTML::FormatText::WithLinks' => 0,
            'Convert::PEM'                => 0,
            'Crypt::JWT'                  => 0,
            'DBI'                         => 0,
            'Email::Sender'               => 1.300027,
            'GD::SecurityImage'           => 0,
            'Glib'                        => 0,
            'HTTP::Message'               => 0,
            'Image::Magick'               => 0,
            'IO::Socket::Timeout'         => 0,
            'IPC::Run'                    => 0,
            'Lasso'                       => '2.3.0',
            'List::MoreUtils'             => 0,
            'LWP::UserAgent'              => 0,
            'LWP::Protocol::https'        => 0,
            'MIME::Entity'                => 0,
            'Net::Facebook::Oauth2'       => 0,
            'Net::LDAP'                   => 0.38,
            'Net::OAuth'                  => 0,
            'Net::OpenID::Consumer'       => 0,
            'Net::OpenID::Server'         => 0,
            'SOAP::Lite'                  => 0,
            'Text::Unidecode'             => 0,
            'Web::ID'                     => 0,
        },
        resources => {
            repository => {
                url  => 'https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng.git',
                web  => 'https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng',
                type => 'git',
            },
            MailingList => 'mailto:lemonldap-ng-dev@ow2.org',
            license     => 'http://opensource.org/licenses/GPL-2.0',
            homepage    => 'https://lemonldap-ng.org/',
            bugtracker  =>
              'https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues',
            x_twitter => 'https://twitter.com/lemonldapng',
        },
    },
    BUILD_REQUIRES => {
        'Authen::Radius'              => 0,
        'Authen::WebAuthn'            => 0,
        'Convert::Base32'             => 0,
        'Convert::PEM'                => 0,
        'Crypt::JWT'                  => 0,
        'DBI'                         => 0,
        'Email::Sender'               => 1.300027,
        'GD::SecurityImage'           => 0,
        'Glib'                        => 0,
        'Hash::Merge::Simple'         => 0,
        'HTML::FormatText::WithLinks' => 0,
        'HTTP::Message'               => 0,
        'Image::Magick'               => 0,
        'IO::Socket::Timeout'         => 0,
        'IO::String'                  => 0,
        'IPC::Run'                    => 0,
        'Lasso'                       => '2.3.0',
        'List::MoreUtils'             => 0,
        'LWP::UserAgent'              => 0,
        'LWP::Protocol::https'        => 0,
        'LWP::Protocol::PSGI'         => 0,
        'MIME::Entity'                => 0,
        'Net::Facebook::Oauth2'       => 0,
        'Net::LDAP'                   => 0.38,
        'Net::OAuth'                  => 0,
        'Net::OpenID::Consumer'       => 0,
        'Net::OpenID::Server'         => 0,
        'Net::SSLeay'                 => 0,
        'SOAP::Lite'                  => 0,
        'Text::Unidecode'             => 0,
        'Time::Fake'                  => 0,
        'Web::ID'                     => 0,
        'XML::LibXML'                 => 0,
    },
    PREREQ_PM => {
        'Clone'                  => 0,
        'Lemonldap::NG::Handler' => '2.22.1',
        'Regexp::Assemble'       => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Portal.pm',    # retrieve abstract from module
            AUTHOR =>
'Xavier Guimard <x.guimard@free.fr>, Clement Oudot <clement@oodo.net>, Christophe Maudoux <chrmdx@gmail.com>, Maxime Besson <maxime.besson@worteks.com>'
          )
        : ()
    ),
    MAN1PODS => $man1,
);
