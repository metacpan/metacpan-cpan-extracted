#!perl
use strict;
use utf8;
use warnings qw(all);

use LWP::Protocol::Net::Curl ftpport => 0;

use LWP::UserAgent;
use Test::More;

plan skip_all => q(these tests are for extended (online) testing; set $ENV{EXTENDED_TESTING} to a true value)
    unless exists $ENV{EXTENDED_TESTING};

my $ua = LWP::UserAgent->new;

my $res;

SKIP: {
    ## no critic (ProhibitPackageVars)
    skip q(no HTTPS support), 3
        unless grep { $_ eq q(https) } @LWP::Protocol::Net::Curl::implements;

    $res = $ua->get(q(https://google.com));
    ok($res->is_success, q(HTTPS is_success()));
    ok($res->is_redirect ? 0 : 1, q(HTTPS not is_redirect()));
    ok($res->redirects > 0, q(HTTPS redirects() == ) . $res->redirects);
}

$res = $ua->get(q(ftp://ftp.cpan.org/pub/CPAN/README));
ok($res->is_success, q(FTP is_success()));
like($res->content, qr(^CPAN:\s+Comprehensive\s+Perl\s+Archive\s+Network\b)x, q(FTP content() start));

$res = $ua->get(q(gopher://gopher.docfile.org/1/world/monitoring/uptime));
ok($res->is_success, q(gopher is_success()));
like($res->content, qr(\bUptime\s+known\s+gopher\s+servers\b)x, q(gopher content() start));

# known to have a long redir chain
$ua->max_redirect(1);
$ua->{show_progress} = 1;
$res = $ua->get(q(http://terra.com.br));
ok($res->is_redirect, q(is_redirect()));

done_testing(8);
