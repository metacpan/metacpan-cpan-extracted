requires 'perl', '5.014';

# HTTP::Tiny, JSON::PP, threads, threads::shared, Thread::Queue, POSIX, Cwd, Sys::Hostname, and
# Carp are all core: this SDK has zero runtime dependencies beyond core Perl.

on 'test' => sub {
    requires 'Test::More', '0.98';
};

# Only needed for the optional PSGI/Dancer2 framework integrations and their own tests: a host
# app that only calls ForgeOps::Tracker::init/report directly never needs either.
recommends 'Plack';
recommends 'Dancer2';
