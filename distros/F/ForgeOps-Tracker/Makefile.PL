use strict;
use warnings;
use ExtUtils::MakeMaker;

# Real deps come from the cpanfile (this repo's own source of truth for what "cpanm --installdeps
# ." needs while developing against sdks/perl directly), not duplicated here by hand, but PAUSE
# indexing and `cpan ForgeOps::Tracker` both go through this file's own PREREQ_PM/TEST_REQUIRES,
# which CPAN's toolchain has no way to read a cpanfile for on its own. Zero runtime dependencies:
# HTTP::Tiny, JSON::PP, threads/threads::shared/Thread::Queue, POSIX, Cwd, Sys::Hostname, and Carp
# are all core Perl 5.14+, the version floor below.
WriteMakefile(
    NAME             => 'ForgeOps::Tracker',
    AUTHOR           => 'ForgeOps <support@getforgeops.net>',
    VERSION_FROM     => 'lib/ForgeOps/Tracker.pm',
    ABSTRACT_FROM    => 'lib/ForgeOps/Tracker.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM        => {},
    TEST_REQUIRES    => {
        'Test::More' => '0.98',
    },
    # Plack/Dancer2 are optional integration targets, not a hard dependency of the core client:
    # matching this file's own cpanfile, which lists them under `recommends`, not `requires`, for
    # exactly that reason. CPAN toolchains have no first-class "recommends" concept of their own
    # (unlike cpanfile), so there's nothing equivalent to add to PREREQ_PM/TEST_REQUIRES here; a
    # host app that wants the Dancer2/PSGI integrations installs those two itself.
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
