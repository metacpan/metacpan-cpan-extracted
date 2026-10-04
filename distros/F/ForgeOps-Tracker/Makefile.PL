use strict;
use warnings;
use ExtUtils::MakeMaker;

# Real deps come from the cpanfile (this repo's own source of truth for what "cpanm --installdeps
# ." needs while developing against sdks/perl directly), not duplicated here by hand, but PAUSE
# indexing and `cpan ForgeOps::Tracker` both go through this file's own PREREQ_PM/TEST_REQUIRES,
# which CPAN's toolchain has no way to read a cpanfile for on its own. HTTP::Tiny, JSON::PP,
# threads/threads::shared/Thread::Queue, POSIX, Cwd, Sys::Hostname, and Carp are all core Perl
# 5.14+, the version floor below. The two runtime prerequisites are what HTTP::Tiny needs to speak
# https, which a ForgeOps DSN always is; the versions are HTTP::Tiny's own minimums.
WriteMakefile(
    NAME             => 'ForgeOps::Tracker',
    AUTHOR           => 'ForgeOps <support@getforgeops.net>',
    VERSION_FROM     => 'lib/ForgeOps/Tracker.pm',
    ABSTRACT_FROM    => 'lib/ForgeOps/Tracker.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM        => {
        'IO::Socket::SSL' => '1.42',
        'Net::SSLeay'     => '1.49',
    },
    # Test-only: Plack, for the local HTTP server the delivery tests post to (HTTP::Server::PSGI,
    # t/lib/EchoServer.pm) and for Plack::Test/Plack::Builder in the PSGI and tracing tests;
    # HTTP::Message (already one of Plack's own prerequisites, so no extra download) for
    # HTTP::Request::Common. Without these, `cpanm ForgeOps::Tracker` failed its own tests on a clean
    # Perl. Still not a runtime dependency: the core client needs neither.
    TEST_REQUIRES    => {
        'Test::More'    => '0.98',
        'Plack'         => '1.0',
        'HTTP::Message' => '6.0',
    },
    # Dancer2 stays optional: its two integration tests skip themselves when it isn't installed
    # (plan skip_all), and a host app that wants the Dancer2 integration installs it itself. CPAN
    # toolchains have no first-class "recommends" concept of their own (unlike cpanfile, which lists
    # it under `recommends`), so it appears in neither PREREQ_PM nor TEST_REQUIRES.
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Luke-Popwell/forge-ops-tracker-perl.git',
                web  => 'https://github.com/Luke-Popwell/forge-ops-tracker-perl',
            },
            bugtracker => {
                web => 'https://github.com/Luke-Popwell/forge-ops-tracker-perl/issues',
            },
            homepage => 'https://getforgeops.net',
        },
    },
    test => { TESTS => 't/*.t' },
);
