requires 'perl', '5.014';

# HTTP::Tiny, JSON::PP, threads, threads::shared, Thread::Queue, POSIX, Cwd, Sys::Hostname, and
# Carp are all core. The only runtime dependencies beyond core Perl are the two modules HTTP::Tiny
# needs to speak https, which a ForgeOps DSN always is: without them nothing can be delivered. The
# versions are HTTP::Tiny's own minimums. Kept in step with Makefile.PL's PREREQ_PM.
requires 'IO::Socket::SSL', '1.42';
requires 'Net::SSLeay', '1.49';

on 'test' => sub {
    requires 'Test::More', '0.98';
    # The delivery tests' local HTTP server (HTTP::Server::PSGI) and the PSGI/tracing tests'
    # Plack::Test; HTTP::Message (a Plack prerequisite anyway) for HTTP::Request::Common. Kept in
    # step with Makefile.PL's TEST_REQUIRES.
    requires 'Plack', '1.0';
    requires 'HTTP::Message', '6.0';
};

# Only needed at runtime for the optional PSGI/Dancer2 framework integrations: a host app that only
# calls ForgeOps::Tracker::init/report directly never needs either. The Dancer2 integration tests
# skip themselves without Dancer2.
recommends 'Plack';
recommends 'Dancer2';
