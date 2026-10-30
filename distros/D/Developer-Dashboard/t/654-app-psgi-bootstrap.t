#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $repo = File::Spec->rel2abs('.');
my $app_psgi = File::Spec->catfile( $repo, 'app.psgi' );
my $home = tempdir( 'dd-app-psgi-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = File::Spec->catdir( $home, 'state' );

my $smoke = q{
use strict;
use warnings;
use HTTP::Request::Common qw(GET);
use Local::PSGITest;
my $file = shift @ARGV;
local $0 = $file;
my $app = do $file or die($@ || $! || "PSGI bootstrap returned no app\n");
my $response = Local::PSGITest::request($app, GET "http://127.0.0.1:7890/system/status");
die "Unexpected PSGI status: " . $response->code . "\n" if !$response->is_success;
print "PSGI /system/status returned " . $response->code . "\n";
};

my ( $stdout, $stderr, $exit ) = capture {
    system $^X, '-I' . File::Spec->catdir( $repo, 't', 'lib' ), '-e', $smoke, $app_psgi;
    return $? >> 8;
};

is( $exit, 0, 'the standalone PSGI bootstrap serves a successful status request' );
is( $stdout, "PSGI /system/status returned 200\n", 'the PSGI status route returns the expected result' );
is( $stderr, '', 'the PSGI bootstrap and route emit no warnings or startup errors' );

done_testing();

__END__

=pod

=head1 NAME

654-app-psgi-bootstrap.t - startup regression test for the PSGI application

=head1 PURPOSE

Run the repository's real C<app.psgi> entrypoint as a child Perl process and
verify that it assembles the standard dashboard application and serves a real
C</system/status> request through the returned PSGI coderef.

=head1 WHY IT EXISTS

The standalone PSGI bootstrap is a supported web startup path. Constructor
requirements in web services can change independently of command-line boot,
so a CLI-only suite does not prove that the PSGI object graph is still wired
correctly. This test caught the missing indicator-store dependency passed to
the prompt renderer.

=head1 WHEN TO USE

Run this test after changing the PSGI bootstrap, prompt dependencies, Dancer2
route setup, or the service constructors used by the web application.

=head1 HOW TO USE

  prove -lv t/654-app-psgi-bootstrap.t

It creates an isolated temporary home and state root, loads C<app.psgi> using
the current Perl interpreter, sends a status request through the returned
PSGI coderef, then checks the process status and both output streams. It does
not open a listening socket or modify the developer's home.

=head1 WHAT USES IT

The test is part of the repository test suite and protects the PSGI bootstrap
used by C<plackup> and the dashboard web-server wrapper.

=head1 EXAMPLES

=over 4

=item *

Run only the bootstrap test while editing the PSGI object wiring:

  prove -lv t/654-app-psgi-bootstrap.t

=item *

Run it together with web route tests after changing Dancer startup:

  prove -lv t/124-favicon-route.t t/125-logout-login-tier-routing.t t/654-app-psgi-bootstrap.t

=back

=cut
