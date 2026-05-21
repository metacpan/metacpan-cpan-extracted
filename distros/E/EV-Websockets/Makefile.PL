use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker 'ev_args';
use Alien::Base::Wrapper ();

my $defines = '';
eval {
    # Try to load local Alien if available in ../Alien-libwebsockets/blib/lib
    push @INC, '../Alien-libwebsockets/blib/lib', '../Alien-libwebsockets/blib/arch';
    require Alien::libwebsockets;
    if (Alien::libwebsockets->has_extensions) {
        $defines .= ' -DLWS_HAS_EXTENSIONS';
    }
};

WriteMakefile(Alien::Base::Wrapper->new('Alien::libwebsockets')->mm_args2(ev_args(
    NAME         => 'EV::Websockets',
    VERSION_FROM => 'lib/EV/Websockets.pm',
    ABSTRACT     => 'WebSocket client/server using libwebsockets and EV',
    AUTHOR       => 'vividsnow',
    LICENSE      => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    DEFINE       => $defines,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'    => 0,
        'EV::MakeMaker'          => 0,
        'Alien::Base::Wrapper'   => 0,
        'Alien::libwebsockets'   => 0,
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'EV' => 4,
    },
    TEST_REQUIRES => {
        'Test::More'                  => 0,
        'AnyEvent'                    => 0,
        'AnyEvent::Socket'            => 0,
        'AnyEvent::Handle'            => 0,
        'AnyEvent::WebSocket::Server' => 0,
        'MIME::Base64'                => 0,
        'Digest::SHA'                 => 0,
    },

    OBJECT => '$(O_FILES)',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'EV::Websockets' => {
                file    => 'lib/EV/Websockets.pm',
                version => MM->parse_version('lib/EV/Websockets.pm'),
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-websockets.git',
                web  => 'https://github.com/vividsnow/perl5-ev-websockets',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-websockets/issues',
            },
        },
    },
)));
