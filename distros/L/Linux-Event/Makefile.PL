use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($^O ne 'linux') {
    print "OS unsupported: Linux::Event supports Linux only\n";
    exit 0;
}

my @public_modules = qw(
    Linux::Event
    Linux::Event::Address
    Linux::Event::Error
    Linux::Event::Framer
    Linux::Event::Framer::DecimalLength
    Linux::Event::Framer::Delimiter
    Linux::Event::Framer::Fixed
    Linux::Event::Framer::LengthPrefix
    Linux::Event::Framer::Netstring
    Linux::Event::Framer::U32BE
    Linux::Event::Framer::Varint
    Linux::Event::IO
    Linux::Event::IO::Pipe
    Linux::Event::IO::TTY
    Linux::Event::IO::Sock
    Linux::Event::IO::Sock::Stream
    Linux::Event::IO::Sock::Listener
    Linux::Event::IO::Sock::Dgram
    Linux::Event::Kernel
    Linux::Event::Kernel::Timer
    Linux::Event::Kernel::Signal
    Linux::Event::Kernel::Event
    Linux::Event::Kernel::Inotify
    Linux::Event::Kernel::Inotify::Watch
    Linux::Event::Kernel::Inotify::Event
    Linux::Event::Kernel::Process
    Linux::Event::Loop
    Linux::Event::TLS
);

my $distribution_version = MM->parse_version('lib/Linux/Event.pm');
my %provides = map {
    my $file = "lib/$_.pm";
    $file =~ s{::}{/}g;
    $_ => {
        file    => $file,
        version => $distribution_version,
    };
} @public_modules;

my %man3pods = map {
    my $module = $_;
    my $file = "lib/$module.pm";
    $file =~ s{::}{/}g;
    $file => "\$(INST_MAN3DIR)/$module.\$(MAN3EXT)";
} @public_modules;

WriteMakefile(
    NAME             => 'Linux::Event',
    VERSION_FROM     => 'lib/Linux/Event.pm',
    ABSTRACT         => 'Linux-native reactor, I/O, kernel events, and processes',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036000',
    DIR              => [qw(xsloop xsbytestream xstls xsconnection xsresolver xssignal xslistener xsevent xsinotify xsdatagram xsprocess)],
    CONFIGURE_REQUIRES => {
        'ExtUtils::CBuilder'  => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Socket' => '2.033',
    },
    MAN3PODS         => \%man3pods,
    META_MERGE       => {
        'meta-spec' => {
            version => 2,
        },
        no_index => {
            package => [qw(
                Linux::Event::_Registration
                Linux::Event::_Deferred
                Linux::Event::_IO
                Linux::Event::_ByteStream
                Linux::Event::_ByteStream::Descriptor
                Linux::Event::_Socket
                Linux::Event::_Socket::Descriptor
                Linux::Event::_Socket::Stream
                Linux::Event::_Socket::Listener
                Linux::Event::_Socket::Dgram
                Linux::Event::_Socket::Connection
                Linux::Event::_ByteStream::_Deadline
                Linux::Event::_ByteStream::Descriptor::Native
                Linux::Event::_ByteStream::State
                Linux::Event::_ByteStream::TestSupport
                Linux::Event::_Socket::Dgram::_ReadyTimer
                Linux::Event::Kernel::Signal::_Descriptor
                Linux::Event::Kernel::Signal::_Engine
                Linux::Event::Kernel::Signal::_Service
                Linux::Event::Kernel::Event::_OwnerState
                Linux::Event::Kernel::Timer::_Descriptor
                Linux::Event::Loop::Introspection
                Linux::Event::Loop::_DeferService
                Linux::Event::_Resolver
                Linux::Event::_Resolver::_Native
                Linux::Event::_SocketConfig
            )],
        },
        provides => \%provides,
        resources => {
            homepage   => 'https://github.com/haxmeister/perl-linux-event',
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-linux-event/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-linux-event.git',
                web  => 'https://github.com/haxmeister/perl-linux-event',
            },
        },
    },
);
