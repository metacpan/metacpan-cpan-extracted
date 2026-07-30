use 5.010000;
use ExtUtils::MakeMaker;
use EV::MakeMaker qw(ev_args);

# Single source of truth for the version, shared with VERSION_FROM below and
# with the explicit 'provides' entries: a stale hardcoded version there is a
# non-increasing version to PAUSE, which can refuse to index the release.
my $version = MM->parse_version('lib/EV/Future.pm');

WriteMakefile(ev_args(
    NAME              => 'EV::Future',
    VERSION_FROM      => 'lib/EV/Future.pm',
    PREREQ_PM         => { 'EV' => '4.37' },
    CONFIGURE_REQUIRES => {
        # TEST_REQUIRES below needs 6.64; older MakeMaker silently ignores the
        # key, and MIN_PERL_VERSION 5.014000 ships one that does (~6.57).
        'ExtUtils::MakeMaker' => '6.64',
        'EV'                  => '4.37',
    },
    TEST_REQUIRES => {
        # The suite calls subtest() throughout without an explicit plan or
        # done_testing() inside the block, relying on subtest's own implicit
        # done_testing(). That became stable in Test::More 0.96 (2010-08-10);
        # subtest() existed earlier (stable since 0.94) but a plan-less block
        # would not auto-finish before 0.96. Source: the Test-Simple Changes
        # file (New Features, 0.95_01, released stable as 0.96).
        'Test::More' => '0.96',
    },
    ABSTRACT_FROM     => 'lib/EV/Future.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.014000',
    PM                => { 'lib/EV/Future.pm' => '$(INST_LIB)/EV/Future.pm' },
    OBJECT            => '$(O_FILES)',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        # EV::Future::Handle is a public, documented class (see the
        # EV::Future::Handle section of EV::Future's POD: cancel, pending,
        # active) whose methods live in Future.xs. lib/EV/Future.pm carries the
        # package stanza, its $VERSION and its documentation, so that is the
        # file both entries point at; Future.xs has neither a package statement
        # nor POD, so naming it left indexers pointing at a file with nothing
        # to read. Listed explicitly, alongside the main package, so a deep vs.
        # shallow META_MERGE of 'provides' can't drop either entry.
        provides => {
            'EV::Future' => {
                file    => 'lib/EV/Future.pm',
                version => $version,
            },
            'EV::Future::Handle' => {
                file    => 'lib/EV/Future.pm',
                version => $version,
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-future.git',
                web  => 'https://github.com/vividsnow/perl5-ev-future',
            },
        },
    },
));
