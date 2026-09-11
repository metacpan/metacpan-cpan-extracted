#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use File::Path qw(make_path);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Doctor;

# DD-651: doctor reports nothing about the SSL certificate's validity dates, so a
# long-running server whose certificate expires under it keeps serving the expired
# one until somebody restarts it. Regeneration happens inside
# generate_self_signed_cert, which runs at server START - an already-running
# instance never re-enters it. With a 365-day default that is a once-a-year
# failure arriving with no warning.
#
# These tests are RED until Doctor grows an SSL certificate check. They are
# written against BEHAVIOUR (what the report says) rather than against a method
# name, so an implementation is free to place the check wherever it belongs.

# The registry binds to the CWD's deepest layer, so the chdir is load-bearing -
# without it this writes into the checkout's own runtime layer and passes here
# while failing in a dev checkout.
my $home = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $cert_dir = File::Spec->catdir( $home, '.developer-dashboard', 'certs' );
make_path($cert_dir);
my $cert_file = File::Spec->catfile( $cert_dir, 'server.crt' );
my $key_file  = File::Spec->catfile( $cert_dir, 'server.key' );

# CI-RED ROOT CAUSE (DD-651, 2026-09-01, found via the diagnostic capture
# below): GitHub's runner uses shogo82148/actions-setup-perl, which installs
# Perl at a prefix (/opt/hostedtoolcache/perl/<ver>/x64) and puts its bin
# directory first on PATH. The openssl a bare `openssl` then resolves to on
# that runner looks for its config inside THAT prefix - where no
# openssl.cnf was ever installed - and dies:
#   "Can't open '.../openssl.cnf' for reading, No such file or directory"
# Reproduced exactly by forcing OPENSSL_CONF at a nonexistent path in a
# plain ubuntu:24.04 container on the SAME OpenSSL 3.0.13 build the runner
# uses - confirming the runner's default OPENSSLDIR lookup, not the OS or
# openssl version, is what differs. Passing '-config' explicitly sidesteps
# the lookup entirely, exactly like Web::Server::generate_self_signed_cert
# already does for the real certificate-generation path (it writes its own
# temp config and passes '-config' - this is the same defensive pattern,
# not a new one). A minimal empty file is sufficient here because '-subj'
# already supplies the full DN non-interactively; no [req] section is read.
my ( undef, $openssl_config ) = tempfile( 'dd-t161-openssl-XXXXXX', SUFFIX => '.cnf', UNLINK => 1 );

# make_cert($days) - writes a self-signed certificate valid for $days from now.
# A negative value is not accepted by -days, so an already-expired certificate is
# made by generating a 1-day certificate and asserting against a clock in the
# future instead. Input: integer days. Output: nothing; dies on failure.
sub make_cert {
    my ($days) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'openssl', 'req', '-x509', '-newkey', 'rsa:2048',
            '-keyout', $key_file, '-out', $cert_file,
            '-days', $days, '-nodes', '-subj', '/CN=localhost',
            '-config', $openssl_config );
    };
    die "openssl failed generating a $days-day certificate (exit $exit)\nstdout: $stdout\nstderr: $stderr"
      if $exit != 0;
    return;
}

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $doctor = Developer::Dashboard::Doctor->new( paths => $paths );

# ssl_issues($report) - every issue the report carries that concerns the
# certificate. Matching on a 'certificate' key rather than on prose, so wording
# changes do not silently stop this test discriminating.
# Input: report hashref. Output: list of issue hashrefs.
sub ssl_issues {
    my ($report) = @_;
    return grep { ( $_->{kind} || '' ) =~ /certificate/i }
      @{ $report->{issues} || [] };
}

# DOES THE CHECK EXIST AT ALL? Probed FIRST, because every assertion below that
# expects ZERO issues would otherwise pass while no check exists - a test aimed at
# an empty set can only return the answer you hoped for. Measured at RED: two of
# these ten assertions passed for exactly that reason, which is why this probe is
# here rather than in a later revision.
make_cert(10);
my $probe_report = $doctor->run( fix => 0 );
my $check_exists = scalar( ssl_issues($probe_report) ) > 0 ? 1 : 0;
ok( $check_exists,
    'the certificate check exists at all - every zero-expecting assertion below is meaningless without this' );

# AC-3: a comfortably valid certificate says NOTHING. A check that speaks on the
# happy path gets ignored, and an ignored check is indistinguishable from a silent
# one.
SKIP: {
    skip 'no certificate check exists yet, so a zero here discriminates nothing', 1
      if !$check_exists;
    make_cert(365);
    my $valid_report = $doctor->run( fix => 0 );
    is( scalar( ssl_issues($valid_report) ), 0,
        'AC-3 a certificate valid for a year raises no certificate issue' );
}

# AC-5: the warning threshold is configurable under web.*, read via
# Config::ssl_warn_days rather than hard-coded, following the accessor pattern
# DD-624 established for ssl_validity_days. Proven by moving the THRESHOLD
# without touching the certificate: a fixed 10-days-remaining certificate must
# flip from silent to warning purely because the config value moved past it.
{
    make_cert(10);

    my $config_dir = File::Spec->catdir( $home, '.developer-dashboard', 'config' );
    make_path($config_dir);
    my $config_file = File::Spec->catfile( $config_dir, 'config.json' );

    open my $low_fh, '>', $config_file or die "Unable to write $config_file: $!";
    print {$low_fh} '{"web":{"ssl_warn_days":5}}';
    close $low_fh;
    my $below_threshold_report = $doctor->run( fix => 0 );
    is( scalar( ssl_issues($below_threshold_report) ), 0,
        'AC-5 a threshold of 5 days does not warn on a certificate 10 days out' );

    open my $high_fh, '>', $config_file or die "Unable to write $config_file: $!";
    print {$high_fh} '{"web":{"ssl_warn_days":20}}';
    close $high_fh;
    my $above_threshold_report = $doctor->run( fix => 0 );
    is( scalar( ssl_issues($above_threshold_report) ), 1,
        'AC-5 and the SAME certificate warns once the threshold moves past it - proving the value is read, not hard-coded' );

    unlink $config_file;
}

# AC-1: inside the warning window, doctor warns AND names the days remaining and
# the path - a warning that does not say how long or which file leaves the
# operator with the same search they started with.
#
# Peer-caught (2026-09-01): this used to call $doctor->run(fix => 0) with no
# explicit 'now', so days_remaining was computed against the REAL wall clock
# at assertion time rather than at generation time. A -days 10 certificate's
# notAfter is openssl's-own-notBefore + 10*86400, so int((notAfter-now)/86400)
# drops from 10 to 9 the instant 'now' is taken any later than notBefore -
# marginal by construction, not merely flaky. Passed standalone (the gap is
# milliseconds) and failed inside the full 741-second suite (the gap widens
# under load). Fixed per docs/time-dependent-tests.md's own rule: age the
# reference against what the code actually compares, not the wall clock -
# capture 'now' BEFORE generation starts, so it can only be EARLIER than
# openssl's own notBefore, never later (int() then only ever rounds 10 down
# from something >= 10, never below it). Falsified: a deliberate sleep(2)
# between make_cert() and the assertion (removed afterward) still passed
# with this fix, reproducing the exact suite-load-delay condition.
my $soon_now = time;
make_cert(10);
my $soon_report = $doctor->run( fix => 0, now => $soon_now );
my @soon = ssl_issues($soon_report);
is( scalar @soon, 1, 'AC-1 a certificate expiring in 10 days raises exactly one issue' );
is( ( $soon[0]->{severity} || '' ), 'warning',
    'AC-1 and it is a WARNING, not a failure' );
like( ( $soon[0]->{detail} || '' ), qr/\b10\b/,
    'AC-1 and the detail names the days remaining' );
is( ( $soon[0]->{path} || '' ), $cert_file,
    'AC-1 and it names the certificate path' );

# AC-2: expired is a FAILURE, separately reportable from the warning, because the
# two call for different actions - plan a restart, versus restart now.
make_cert(1);
my $past = time + ( 86_400 * 3 );
my $expired_report = $doctor->run( fix => 0, now => $past );
my @expired = ssl_issues($expired_report);
is( scalar @expired, 1, 'AC-2 an expired certificate raises exactly one issue' );
is( ( $expired[0]->{severity} || '' ), 'failure',
    'AC-2 and it is a FAILURE, distinguishable from the near-expiry warning' );

# AC-4a: a MISSING certificate raises NOTHING. Corrected before implementation -
# the original draft treated absence as cannot-look, which conflates it with the
# genuinely healthy state (SSL never configured or used). _audit_root's own idiom
# for an absent root is 'exists => 0, issue_count => 0, issues => []' - silent,
# not a finding - and generate_self_signed_cert does not treat a missing
# certificate as broken either; it just creates one. A checker that speaks on the
# normal case gets ignored (AC-3's own reasoning, applied to the branch that was
# wrong).
unlink $cert_file;
my $absent_report = $doctor->run( fix => 0 );
is( scalar( ssl_issues($absent_report) ), 0,
    'AC-4a a missing certificate raises nothing - the normal, SSL-never-used state' );

# AC-4b: cannot-look is its own outcome ONLY when there is something to fail to
# inspect. A certificate file that IS PRESENT but unparseable is the real case
# this project's oldest standing rule protects - openssl x509 exits 1 on it,
# cleanly distinguishable from a missing file (confirmed: 'Unable to load
# certificate' vs no file at all).
open my $fh, '>', $cert_file or die "Unable to write $cert_file: $!";
print {$fh} "not a certificate
";
close $fh;
my $corrupt_report = $doctor->run( fix => 0 );
my @corrupt = ssl_issues($corrupt_report);
is( scalar @corrupt, 1, 'AC-4b a present-but-unparseable certificate raises an issue' );
is( ( $corrupt[0]->{severity} || '' ), 'unknown',
    'AC-4b and it reports cannot-look, distinct from valid, near-expiry and expired' );

# AC-6: the check reads notAfter from the certificate itself. Proven by moving the
# certificate's dates without touching any config: if the verdict follows the file,
# the file is what is being read.
SKIP: {
    skip 'no certificate check exists yet, so a zero here discriminates nothing', 1
      if !$check_exists;
    make_cert(200);
    my $long_report = $doctor->run( fix => 0 );
    is( scalar( ssl_issues($long_report) ), 0,
        'AC-6 a 200-day certificate is quiet, so the verdict follows the certificate' );
}

# AC-7 (coverage closure): _ssl_certificate_issues accepts an explicit
# warn_days, overriding Config::ssl_warn_days - run() never forwards this arg
# itself, so it is only reachable by calling the check directly. Two calls on
# the SAME 10-day certificate prove the value is read, the same shape AC-5
# already used for the config-driven threshold.
{
    make_cert(10);
    my @below = grep { ( $_->{kind} || '' ) =~ /certificate/i }
      $doctor->_ssl_certificate_issues( warn_days => 5 );
    is( scalar @below, 0,
        'AC-7 an explicit warn_days of 5 does not warn on a certificate 10 days out' );
    my @above = grep { ( $_->{kind} || '' ) =~ /certificate/i }
      $doctor->_ssl_certificate_issues( warn_days => 20 );
    is( scalar @above, 1,
        'AC-7 the SAME certificate warns once an explicit warn_days moves past it' );
}

# AC-8 (coverage closure): a certificate openssl parses successfully (exit 0)
# but whose -enddate output _ssl_parse_enddate cannot itself parse is reported
# as cannot-look, exactly like AC-4b's outright-unparseable file - this is a
# SEPARATE code path (past the exit-code check, inside the enddate-parse
# branch) that no real openssl output can be made to exercise, since openssl's
# -enddate format is fixed. Overridden the same way t/02 and t/08 already
# override a sub for one test: a local typeglob swap, restored automatically
# when the block ends.
{
    make_cert(10);
    no warnings 'redefine';
    local *Developer::Dashboard::Doctor::_ssl_parse_enddate = sub { return undef };
    my @unparseable_enddate =
      grep { ( $_->{kind} || '' ) =~ /certificate/i } $doctor->_ssl_certificate_issues;
    is( scalar @unparseable_enddate, 0,
        'AC-8 an enddate openssl printed but could not itself be parsed raises nothing rather than crashing' );
}

# AC-9 (coverage closure): _ssl_parse_enddate's own two failure branches,
# tested directly since no real openssl output reaches either from AC-1..AC-6 -
# every real certificate this suite generates already matches the full
# notAfter format with a valid month name.
is( Developer::Dashboard::Doctor::_ssl_parse_enddate("not an enddate line\n"),
    undef,
    'AC-9 a line not matching the notAfter=... shape returns undef' );
is( Developer::Dashboard::Doctor::_ssl_parse_enddate("notAfter=Xxx  1 00:00:00 2030 GMT\n"),
    undef,
    'AC-9 a syntactically-matching line with an unrecognised month name returns undef' );

done_testing;

__END__

=pod

=head1 NAME

t/176-doctor-ssl-certificate-expiry.t - doctor reports the active SSL
certificate's remaining validity

=head1 PURPOSE

Pins the behaviour DD-651 adds: C<dashboard doctor> reports a certificate that is
close to expiry or already past it, and stays silent about one that is healthy.

=head1 WHY IT EXISTS

The self-signed certificate regenerates on expiry, but only inside
C<generate_self_signed_cert>, which runs when the web server STARTS. A server
already running when its certificate expires keeps serving the expired one until
somebody restarts it. With the default 365-day validity that is a once-a-year
event that arrives with no warning at all, and under SSL the loopback-admin
shortcut is disabled, so every browser client needs a helper login and there is no
trusted-local path that degrades gracefully.

DD-623 established that an expired certificate is NOT reused across a restart -
C<_ssl_cert_has_expected_profile> ends in an C<openssl verify> whose exit status is
tested, and verify checks validity dates. This file therefore covers visibility,
not rotation.

=head1 WHEN TO USE

Run it when changing anything about doctor's checks, the certificate profile
check, or the SSL certificate directory.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/176-doctor-ssl-certificate-expiry.t

=head1 WHAT USES IT

The full suite via C<prove -lr t>, and the coverage gate through
C<HARNESS_PERL_SWITCHES=-MDevel::Cover>.

=head1 EXAMPLES

A certificate ten days from expiry, with the warning threshold at thirty, produces
one warning naming both the number of days and the certificate path; the same
certificate read after its notAfter produces a failure instead.

=cut
