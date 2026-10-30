use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($^O ne 'linux') {
    print "OS unsupported: Linux::Event::HTTP supports Linux only\n";
    exit 0;
}

my @public_modules = qw(
    Linux::Event::HTTP
    Linux::Event::HTTP::Client
    Linux::Event::HTTP::Server
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
    ABSTRACT         => 'Linux-native integration of Unblock HTTP',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036000',
    DIR              => [qw(xsbridge)],
    # Only the rebuilt Unblock-based public API is tested and shipped.
    test             => { TESTS => 't/rebuild/*.t' },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Unblock::HTTP1' => '0.13',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Linux::Event'        => '0.117',
        'Unblock::HTTP'       => '0.03',
        'Unblock::HTTP1'      => '0.13',
        'Uniform::HTTP'       => '0.06',
    },
    META_MERGE => {
        optional_features => {
            http3 => {
                description => 'HTTP/3 over verified QUIC/TLS (optional)',
                prereqs => { runtime => { requires => {
                    'Unblock::HTTP3' => '0.14', 'Net::QUIC' => '0.06',
                } } },
            },
            websocket => {
                description => 'Optional WebSocket protocol transition',
                prereqs => { runtime => { requires => {
                    'Unblock::WebSocket' => '0.02',
                } } },
            },
            http2 => {
                description => 'HTTP/2 over TLS with ALPN',
                prereqs => { runtime => { requires => { 'Unblock::HTTP2' => '0.13' } } },
            },
        },
        'meta-spec' => {
            version => 2,
        },
        no_index => {
            package => [qw(
                Linux::Event::HTTP::_Config
                Linux::Event::HTTP::_Stream
                Linux::Event::HTTP::_Transport
                Linux::Event::HTTP::_UpgradedStream
                Linux::Event::HTTP::_QUICSocket
                Linux::Event::HTTP::_NativeStream
                Linux::Event::HTTP::_NativeBridge
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
