#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Developer::Dashboard::Web::Server;

# internal_sockhost()
# Returns the test backend host required by the SSL command builder.
# Input: daemon fixture object.
# Output: loopback host string.
sub Local::DashboardTestDaemon::internal_sockhost { return '127.0.0.1' }

# internal_sockport()
# Returns the test backend port required by the SSL command builder.
# Input: daemon fixture object.
# Output: positive port integer.
sub Local::DashboardTestDaemon::internal_sockport { return 23456 }

my @spawned;
my $server = bless {
    ssl_backend_command_builder => sub { return [ $^X, '-e', 'exit 7' ] },
}, 'Developer::Dashboard::Web::Server';

{
    no warnings 'redefine';
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        @spawned = @_;
        die "simulated GoRoutine process launch failure\n";
    };
    my $ok = eval {
        $server->_serve_ssl_frontend( bless {}, 'Local::DashboardTestDaemon' );
        1;
    };
    ok( !$ok, 'the SSL frontend reports a GoRoutine process launch failure' );
    like( $@, qr/simulated GoRoutine process launch failure/, 'the process-launch error is propagated visibly' );
    is_deeply( \@spawned, [ [ $^X, '-e', 'exit 7' ], { process_group => 1 } ],
        'the SSL backend command is launched as a separately managed process group' );
}

done_testing;

__END__

=pod

=head1 NAME

t/682-server-backend-exit-s7-coverage.t - covers the GoRoutine SSL backend process launch boundary

=head1 PURPOSE

This regression test verifies that the SSL frontend delegates backend startup
to GoRoutine's native process API, requests a separately manageable process
group, and propagates a process-launch failure without swallowing it.

=head1 WHY IT EXISTS

It exists because process startup is an external boundary whose failure must be
visible and whose process-group option is required for bounded backend cleanup.

=head1 WHEN TO USE

Use this file when changing SSL backend startup or the GoRoutine process API
integration.

=head1 HOW TO USE

Run it in the dev Docker container:

  d2 docker compose exec dev prove -lv t/682-server-backend-exit-s7-coverage.t

=head1 WHAT USES IT

It is used by the full test suite and the coverage gate to verify the SSL
frontend's process-launch boundary.

=head1 EXAMPLES

Example:

  d2 docker compose exec dev prove -lv t/682-server-backend-exit-s7-coverage.t

The test injects a literal child argv vector, substitutes a failing launcher,
and checks both the process-group option and visible error propagation.

=cut
