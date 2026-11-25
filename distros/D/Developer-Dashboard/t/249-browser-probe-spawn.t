#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($RealBin);
use Test::More;

use lib File::Spec->catdir( $RealBin, 'lib' );
use Local::BrowserProbe qw(browser_can_fetch_loopback);

my $helper_path = File::Spec->catfile( $RealBin, 'lib', 'Local', 'BrowserProbe.pm' );
open my $helper_fh, '<', $helper_path or die "Unable to read browser-probe helper '$helper_path': $!";
my $helper_source = do { local $/; <$helper_fh> };
close $helper_fh or die "Unable to close browser-probe helper '$helper_path': $!";
unlike( $helper_source, qr/\bfork\s*\(/, 'browser probe starts its local server through GoRoutine, not Perl fork' );

my $browser = q{
    use IO::Socket::INET;
    my ($url) = grep { /\Ahttp:\/\// } @ARGV;
    die "loopback URL missing\n" if !defined $url;
    $url =~ m{\Ahttp://([^:/]+):(\d+)/} or die "loopback URL invalid\n";
    my $socket = IO::Socket::INET->new( PeerAddr => $1, PeerPort => $2, Proto => 'tcp' )
      or die "loopback connect failed: $!\n";
    print {$socket} "GET / HTTP/1.0\r\nHost: $1\r\nConnection: close\r\n\r\n";
    while ( my $line = <$socket> ) { print $line }
    close $socket or die "loopback socket close failed: $!\n";
};

my ( $ok, $reason ) = browser_can_fetch_loopback(
    browser => $^X,
    args    => [ '-e', $browser, '--' ],
    seconds => 5,
);
ok( $ok, 'the probe serves a loopback page and its child browser fetches it' ) or diag $reason;
is( $reason, '', 'a successful browser probe has no skip reason' );

done_testing;

__END__

=head1 NAME

t/249-browser-probe-spawn.t - browser probe subprocess contract tests

=head1 PURPOSE

Verify that C<Local::BrowserProbe> serves its loopback readiness page and runs
its browser command without calling Perl's process-creation primitive directly.

=head1 WHY IT EXISTS

The system-menu and GoRoutine migration requires repository test helpers to use
the shared GoRoutine process interface. The existing browser probe launches a
minimal server so an unavailable local browser can be distinguished from a
product failure. This test protects both the real HTTP exchange and the process
API boundary.

=head1 WHEN TO USE

Run this test when changing the browser probe, its child server, or GoRoutine
process lifecycle code.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/249-browser-probe-spawn.t

The test launches a Perl one-liner as a fake browser. That client requests the
probe's HTTP page and returns the response to the helper, which must recognize
the expected marker.

=head1 WHAT USES IT

The Docker test suite runs this contract alongside the browser end-to-end tests
in C<t/33-web-server-ssl-browser.t> and C<t/38-web-no-editor-browser.t>.

=head1 EXAMPLES

Run only the browser process contract:

  d2 docker compose exec dev prove -lv t/249-browser-probe-spawn.t

Run it with the bounded process lifecycle contract:

  d2 docker compose exec dev prove -lv t/152-bounded-command.t t/249-browser-probe-spawn.t

=cut
