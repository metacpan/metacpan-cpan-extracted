use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($^O ne 'linux') {
    print "OS unsupported: Linux::Event::HTTP supports Linux only\n";
    exit 0;
}

my @public_modules = qw(
    Linux::Event::HTTP
    Linux::Event::HTTP::Body::Stream
    Linux::Event::HTTP::Client
    Linux::Event::HTTP::Client::Connection
    Linux::Event::HTTP::Client::Operation
    Linux::Event::HTTP::Server
    Linux::Event::HTTP::Server::Connection
    Linux::Event::HTTP::Request
    Linux::Event::HTTP::Response
    Linux::Event::HTTP::Transaction
);

my $distribution_version = MM->parse_version('lib/Linux/Event/HTTP.pm');
my %provides = map {
    my $file = "lib/$_.pm";
    $file =~ s{::}{/}g;
    $_ => {
        file    => $file,
        version => $distribution_version,
    };
} @public_modules;

WriteMakefile(
    NAME             => 'Linux::Event::HTTP',
    VERSION_FROM     => 'lib/Linux/Event/HTTP.pm',
    ABSTRACT         => 'Native high-performance HTTP protocol support for Linux::Event',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036000',
    DIR              => [qw(xshttp1)],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTTP::CookieJar'     => '0.014',
        'Linux::Event'        => '0.116',
        'Uniform::HTTP::Auth' => '0.02',
        'URI'                 => 0,
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        no_index => {
            package => [qw(
                Linux::Event::HTTP::_ClientAuth
                Linux::Event::HTTP::_ClientConnect
                Linux::Event::HTTP::_ClientUpgrade
                Linux::Event::HTTP::_HTTP1
                Linux::Event::HTTP::_HTTP1::Chunked
                Linux::Event::HTTP::_ServerConnect
                Linux::Event::HTTP::_Upgrade
            )],
        },
        provides => \%provides,
        resources => {
            homepage   => 'https://github.com/haxmeister/perl-Linux-Event-HTTP',
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Linux-Event-HTTP/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Linux-Event-HTTP.git',
                web  => 'https://github.com/haxmeister/perl-Linux-Event-HTTP',
            },
        },
    },
);
