#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;
use Fetch::CookieJar;

# Fetch::CookieJar: the matching rules in isolation, then the real flow - a
# login that sets a cookie on a 302 and the followed request carrying it, plus
# ordinary send-back on later requests.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    $SIG{CHLD} = 'IGNORE';
    while (my $c = $srv->accept) {
        my $kid = fork;
        if (defined $kid && $kid == 0) {
            $c->autoflush(1);
            while (my $line = <$c>) {
                my ($m, $p) = $line =~ m{^(\S+)\s+(\S+)};
                my $cookie = '';
                while (my $h = <$c>) {
                    $cookie = $1 if $h =~ /^Cookie:\s*(.*?)\r/i;
                    last if $h eq "\r\n";
                }
                my ($status, $extra, $b) = ('200 OK', '', '');
                if ($p eq '/login') {
                    $status = '302 Found';
                    $extra  = "Set-Cookie: sid=abc123; Path=/\r\nLocation: /account\r\n";
                } elsif ($p eq '/account') {
                    $b = "seen=$cookie";
                } elsif ($p eq '/setmulti') {
                    $extra = "Set-Cookie: a=1; Path=/\r\nSet-Cookie: b=2; Path=/\r\n";
                    $b = 'ok';
                } else {
                    $b = "seen=$cookie";
                }
                print $c "HTTP/1.1 $status\r\nContent-Type: text/plain\r\n$extra"
                       . "Content-Length: " . length($b) . "\r\n"
                       . "Connection: close\r\n\r\n$b";
                close $c;
                last;
            }
            exit 0;
        }
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.3);

plan tests => 13;

# ---- unit: parsing and matching ------------------------------------------
{
    my $jar = Fetch::CookieJar->new;

    $jar->set_cookie('sid=xyz; Path=/app', 'example.com', '/app/page');
    is($jar->cookie_header('example.com', '/app/page', 0), 'sid=xyz',
        'path-scoped cookie sent on a matching path');
    is($jar->cookie_header('example.com', '/other', 0), undef,
        'not sent on a non-matching path');

    $jar->set_cookie('s=1; Secure', 'example.com', '/');
    is($jar->cookie_header('example.com', '/app/page', 0), 'sid=xyz',
        'Secure cookie withheld over plain http (only the path cookie sent)');
    like($jar->cookie_header('example.com', '/app/page', 1), qr/\bs=1\b/,
        'Secure cookie sent over https');

    # subdomain via explicit Domain
    $jar->set_cookie('d=1; Domain=example.com; Path=/', 'example.com', '/');
    like($jar->cookie_header('api.example.com', '/', 0), qr/\bd=1\b/,
        'Domain cookie sent to a subdomain');

    # host-only cookie not sent to a subdomain
    my $ho = Fetch::CookieJar->new;
    $ho->set_cookie('h=1', 'example.com', '/');
    is($ho->cookie_header('api.example.com', '/', 0), undef,
        'host-only cookie not sent to a subdomain');

    # expiry: Max-Age=0 deletes
    $jar->set_cookie('d=1; Domain=example.com; Path=/; Max-Age=0', 'example.com', '/');
    unlike($jar->cookie_header('example.com', '/', 0) || '', qr/\bd=1\b/,
        'Max-Age=0 removes the cookie');

    # a foreign Domain is rejected
    my $rej = Fetch::CookieJar->new;
    $rej->set_cookie('x=1; Domain=evil.com', 'example.com', '/');
    is($rej->count, 0, 'cookie for an unrelated domain is rejected');
}

# ---- over the wire: login sets a cookie, redirect + later requests carry it
{
    my $ua = Fetch->new(cookie_jar => 1);

    my $res = $ua->get("$base/login")->get;         # 302 -> /account
    is($res->content, 'seen=sid=abc123',
        'cookie set on the 302 is carried to the followed redirect');
    is($ua->cookie_jar->count, 1, 'the jar holds the login cookie');

    is($ua->get("$base/next")->get->content, 'seen=sid=abc123',
        'a later request sends the stored cookie');

    $ua->get("$base/setmulti")->get;
    like($ua->get("$base/again")->get->content, qr/a=1/,
        'multiple Set-Cookie values are all stored');
    like($ua->get("$base/again")->get->content, qr/b=2/,
        'and all sent back together');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
