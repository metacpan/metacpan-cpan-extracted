#!/usr/bin/env perl

use strict;
use warnings;

# CORE::GLOBAL::fork and exit overrides must exist before Web::Server is
# compiled. They are inert unless a test arms them, so the backend child branch
# of the SSL frontend can be driven in-process without really forking or
# terminating the test run.
our ( $FORK_HOOK, $EXIT_HOOK );

BEGIN {
    *CORE::GLOBAL::fork = sub () {
        return $FORK_HOOK->() if $FORK_HOOK;
        return CORE::fork();
    };
    *CORE::GLOBAL::exit = sub (;$) {
        die bless( { code => ( @_ ? $_[0] : 0 ) }, 'Local::Exit' ) if $EXIT_HOOK;
        CORE::exit( @_ ? $_[0] : 0 );
    };
}

use Test::More;

use lib 'lib';

use Developer::Dashboard::Web::Server;

my $server = bless {}, 'Developer::Dashboard::Web::Server';

{
    no warnings 'redefine';
    my @daemons;
    local *Developer::Dashboard::Web::Server::_run_ssl_backend_process = sub {
        push @daemons, $_[1];
        return 7;
    };
    local $FORK_HOOK = sub { return 0 };
    local $EXIT_HOOK = 1;
    my $ok = eval { $server->_serve_ssl_frontend( { marker => 'daemon' } ); 1 };
    ok( !$ok, 'the backend child never returns to the frontend loop' );
    isa_ok( $@, 'Local::Exit', 'the backend child leaves through exit' );
    is( $@->{code}, 7, 'the backend child exits with the backend process status' );
    is_deeply( \@daemons, [ { marker => 'daemon' } ], 'the backend child receives the daemon descriptor' );
}

done_testing;

__END__

=pod

=head1 NAME

t/682-server-backend-exit-s7-coverage.t - covers the backend-child exit of the SSL frontend in Developer::Dashboard::Web::Server

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It arms BEGIN-time fork and exit overrides so the forked backend child branch of _serve_ssl_frontend runs in-process.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch must be reached by a real test or removed from the code.

=head1 WHEN TO USE

Use this file when you change the code paths it exercises, or when a coverage run reports one of them as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/682-server-backend-exit-s7-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/682-server-backend-exit-s7-coverage.t

Run this coverage-gap test by itself while editing the code it covers.

=cut
