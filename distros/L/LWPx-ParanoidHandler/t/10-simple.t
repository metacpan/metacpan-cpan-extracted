#!/usr/bin/perl
#

use strict;
use lib 'lib';
use LWPx::ParanoidHandler;
use LWP::UserAgent;
use Time::HiRes qw(time);
use Test::More tests => 16;
use Net::DNS;
use IO::Socket::INET;
use t::MockResolver;

my ($t1, $td);
my $delta = sub { printf " %.03f secs\n", $td; };


my $mock_resolver = do {
    my $mock_resolver = t::MockResolver->new;

    # Record pointing to localhost:
    {
        my $packet = Net::DNS::Packet->new;
        $packet->push(answer => Net::DNS::RR->new("localhost-fortest.danga.com. 86400 A 127.0.0.1"));
        $mock_resolver->set_fake_record("localhost-fortest.danga.com", $packet);
    }

    # CNAME to blocked destination:
    {
        my $packet = Net::DNS::Packet->new;
        $packet->push(answer => Net::DNS::RR->new("bradlj-fortest.danga.com 300 IN CNAME brad.lj"));
        $mock_resolver->set_fake_record("bradlj-fortest.danga.com", $packet);
    }

    $mock_resolver;
};

my $ua = LWP::UserAgent->new;
$ua->env_proxy;

ok((ref $ua) =~ /LWP::UserAgent/);
my $dns = Net::DNS::Paranoid->new(resolver => $mock_resolver);
make_paranoid($ua, $dns);

my ($HELPER_IP, $HELPER_PORT) = ("127.66.74.70", 9001);

$dns->whitelisted_hosts( [ $HELPER_IP, ] );

$dns->blocked_hosts( [ qr/\.lj$/, "1.2.3.6", ] );

subtest 'hostnames pointing to internal IPs' => sub {
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    my $dns = Net::DNS::Paranoid->new(resolver => $mock_resolver);
    make_paranoid($ua, $dns);

    my $res = $ua->get("http://localhost-fortest.danga.com/");
    ok(! $res->is_success);
    like($res->status_line, qr/Suspicious DNS results/);
};

subtest 'random IP address forms' => sub {
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    make_paranoid($ua);

    my $res = $ua->get("http://0x7f.1/");
    ok(!$res->is_success);
    ok($res->status_line =~ /blocked/, '0x7f.1');
    $res = $ua->get("http://0x7f.0xffffff/");
    ok(! $res->is_success && $res->status_line =~ /blocked/);
    $res = $ua->get("http://037777777777/");
    ok(! $res->is_success && $res->status_line =~ /blocked/);
    $res = $ua->get("http://192.052000001/");
    ok(! $res->is_success && $res->status_line =~ /blocked/);
    $res = $ua->get("http://0x00.00/");
    ok(! $res->is_success && $res->status_line =~ /blocked/);
};


subtest 'test the the blocked host above in decimal form is blocked by this non-decimal form' => sub {
    note 'trying';
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    make_paranoid($ua, $dns);

    my $res = $ua->get("http://0x01.02.0x306/");
    ok(! $res->is_success && $res->status_line =~ /blocked/, '0x01.02.0x306');
};

subtest 'more blocked spaces' => sub {
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    make_paranoid($ua, $dns);

    my $res = $ua->get("http://192.0.2.13/");
    ok(! $res->is_success && $res->status_line =~ /blocked/);
    $res = $ua->get("http://192.88.99.77/");
    ok(! $res->is_success && $res->status_line =~ /blocked/, '192.88.99.77');
};

subtest 'hostnames doing CNAMEs (this one resolves to "brad.lj", which is verboten)' => sub {
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    make_paranoid($ua, $dns);

    my $res = $ua->get("http://bradlj-fortest.danga.com/");
    ok(! $res->is_success);
    like($res->status_line, qr/DNS lookup resulted in bad host/);
};
my $res;
my $ua = LWP::UserAgent->new();
$ua->env_proxy;
make_paranoid($ua, $dns);

subtest "can't do empty host name" => sub {
    $res = $ua->get('');
    print $res->status_line, "\n";
    ok(! $res->is_success);
};

subtest "black-listed via blocked_hosts" => sub {
    $res = $ua->get("http://brad.lj/");
    ok(! $res->is_success);
};

subtest "can't do octal in IPs" => sub {
    $res = $ua->get("http://012.1.2.1/");
    ok(! $res->is_success);
};

subtest "can't do decimal/octal IPs" => sub {
    $res = $ua->get("http://167838209/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
};

subtest " checking that port isn't affected" => sub {
    $res = $ua->get("http://brad.lj:80/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
};

subtest "this domain is okay.  bradfitz.com isn't blocked" => sub {
    $res = $ua->get("http://bradfitz.com/");
    print $res->status_line, "\n";
    ok(  $res->is_success);
};

# SSL should still work, assuming it would work before.
SKIP:
{
    my $has_ssleay = eval { require Crypt::SSLeay; 1;   };
    my $has_iossl  = eval { require IO::Socket::SSL; 1; };

    skip "Crypt::SSLeay or IO::Socket::SSL not installed", 1 unless $has_ssleay || $has_iossl;

    $res = $ua->get("https://pause.perl.org/pause/query");
    ok(  $res->is_success && $res->content =~ /Login|PAUSE|Edit/);
}

subtest 'internal. bad.  blocked by default by module.' => sub {
    $res = $ua->get("http://10.2.3.4/");
    note $res->status_line;
    ok(! $res->is_success);
};

subtest 'okay' => sub {
    $res = $ua->get("http://danga.com/temp/");
    note $res->status_line;
    ok(  $res->is_success);
};

subtest 'localhost is blocked, case insensitive' => sub {
    $res = $ua->get("http://LOCALhost/temp/");
    note $res->status_line;
    ok(! $res->is_success);
};

exit;

sub new_ua {
    my $ua = LWP::UserAgent->new(timeout => 5);
    $ua->env_proxy;

    my $dns = Net::DNS::Paranoid->new(@_);
    make_paranoid($ua, $dns);
    return $ua;
}
