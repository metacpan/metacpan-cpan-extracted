use v5.36;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my @public_modules = qw(
    Linux::Event::WebSocket
    Linux::Event::WebSocket::Client
    Linux::Event::WebSocket::Client::Connection
    Linux::Event::WebSocket::Connection
    Linux::Event::WebSocket::Server
    Linux::Event::WebSocket::Server::Connection
);

my $distribution_version = MM->parse_version('lib/Linux/Event/WebSocket.pm');
my %provides = map {
    my $file = "lib/$_.pm";
    $file =~ s{::}{/}g;
    $_ => {
        file    => $file,
        version => $distribution_version,
    };
} @public_modules;

WriteMakefile(
    NAME          => 'Linux::Event::WebSocket',
    VERSION_FROM  => 'lib/Linux/Event/WebSocket.pm',
    ABSTRACT_FROM => 'lib/Linux/Event/WebSocket.pm',
    AUTHOR        => 'Joshua S. Day <hax@cpan.org>',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.036000',
    XS => {
        'WebSocket.xs' => 'WebSocket.c',
    },
    clean => {
        FILES => 'WebSocket.c',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index => {
            package => [qw(
                Linux::Event::WebSocket::_BQ
                Linux::Event::WebSocket::_Engine
                Linux::Event::WebSocket::_Frame
                Linux::Event::WebSocket::_Handshake
                Linux::Event::WebSocket::_Parser
                Linux::Event::WebSocket::_Random
                Linux::Event::WebSocket::_State
                Linux::Event::WebSocket::_UTF8
                Linux::Event::WebSocket::Client::_HTTPConnection
                Linux::Event::WebSocket::Server::_HTTPConnection
            )],
        },
        provides => \%provides,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Linux-Event-WebSocket.git',
                web  => 'https://github.com/haxmeister/perl-Linux-Event-WebSocket',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Linux-Event-WebSocket/issues',
            },
        },
    },
    PREREQ_PM => {
        'Digest::SHA'         => 0,
        'Linux::Event'        => '0.116',
        'Linux::Event::HTTP'  => '0.002',
        'MIME::Base64'        => 0,
        'URI'                 => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
);
