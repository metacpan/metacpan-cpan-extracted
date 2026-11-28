use strict;
use warnings;
use Test::More;
use lib 't/lib';
use SmtpdHarness qw( run_filter session report filter );

plan skip_all => 'OpenSMTPd::Filter not installed'
    unless eval { require OpenSMTPd::Filter; 1 };

# --- relay check -----------------------------------------------------------
my $r = run_filter(
    args  => ['-r'],
    mx    => sub { "ok 0 Not%20today 554 5.7.1 0\n" },
    lines => [
        report( 'link-connect', 'S1', 'mx.example.org', 'pass', '[2001:db8::1]:3333', '[2001:db8::2]:25' ),
        filter( 'connect', 'S1', 'T1', 'mx.example.org', '[2001:db8::1]:3333' ),
    ],
);
is_deeply $r->{out}, ['filter-result|S1|T1|reject|554 5.7.1 Not today'],
    'relay rejection keeps code, dsn and text from filter_relay';
is $r->{mx}[0], 'relayok 2001:db8::1 mx.example.org 3333 2001:db8::2 25 NOQUEUE',
    'relayok has the documented arguments, IPv6 without brackets';

$r = run_filter(
    args  => ['-r'],
    mx    => sub { "ok -1 ? 451 4.3.0 0\n" },
    lines => [
        report( 'link-connect', 'S1', '<unknown>', 'fail', '192.0.2.1:3333', '192.0.2.2:25' ),
        filter( 'connect', 'S1', 'T1', '<unknown>', '192.0.2.1:3333' ),
    ],
);
is_deeply $r->{out}, ['filter-result|S1|T1|reject|451 4.3.0 relay not allowed.'],
    'relay tempfail';
like $r->{mx}[0], qr/^relayok 192\.0\.2\.1 \[192\.0\.2\.1\] 3333 /, 'no rDNS becomes [ip]';

$r = run_filter(
    args  => [],
    mx    => sub { die "must not be called" },
    lines => [
        report( 'link-connect', 'S1', 'mx.example.org', 'pass', '192.0.2.1:3333', '192.0.2.2:25' ),
        filter( 'connect', 'S1', 'T1', 'mx.example.org', '192.0.2.1:3333' ),
    ],
);
is_deeply $r->{out}, ['filter-result|S1|T1|proceed'], 'relay check is off by default';
is scalar @{ $r->{mx} }, 0, 'multiplexor not contacted';

# --- helo check ------------------------------------------------------------
$r = run_filter(
    args  => ['-H'],
    mx    => sub { "ok 0 Bad%20HELO 554 5.7.1 0\n" },
    lines => [
        report( 'link-connect', 'S1', 'mx.example.org', 'pass', '192.0.2.1:3333', '192.0.2.2:25' ),
        report( 'link-greeting', 'S1', 'mail.example.net' ),
        filter( 'ehlo', 'S1', 'T1', 'evil.example.com' ),
    ],
);
is_deeply $r->{out}, ['filter-result|S1|T1|reject|554 5.7.1 Bad HELO'], 'helo rejection';
is $r->{mx}[0], 'helook 192.0.2.1 mx.example.org evil.example.com 3333 192.0.2.2 25 NOQUEUE',
    'helook uses the client name, not the local greeting hostname';

# --- accept without further filtering --------------------------------------
$r = run_filter(
    args  => [ '-r', '-H' ],
    mx    => sub { "ok 2 ? 250 2.1.0 0\n" },
    lines => [
        report( 'link-connect', 'S1', 'mx.example.org', 'pass', '192.0.2.1:3333', '192.0.2.2:25' ),
        filter( 'connect', 'S1', 'T1', 'mx.example.org', '192.0.2.1:3333' ),
        filter( 'ehlo', 'S1', 'T2', 'client.example.org' ),
    ],
);
is_deeply $r->{out},
    [ 'filter-result|S1|T1|proceed', 'filter-result|S1|T2|proceed' ],
    'ok 2 skips later checks';
is scalar @{ $r->{mx} }, 1, 'helook not asked after ok 2';

# --- multiplexor down ------------------------------------------------------
$r = run_filter(
    args  => ['-r'],
    mx    => sub { undef },    # closes without answering
    lines => [
        report( 'link-connect', 'S1', 'mx.example.org', 'pass', '192.0.2.1:3333', '192.0.2.2:25' ),
        filter( 'connect', 'S1', 'T1', 'mx.example.org', '192.0.2.1:3333' ),
    ],
);
is_deeply $r->{out}, ['filter-result|S1|T1|reject|451 4.3.0 Temporary failure, please try again later.'],
    'no answer from the multiplexor is a tempfail';

done_testing;
