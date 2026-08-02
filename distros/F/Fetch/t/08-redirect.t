#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;

# Redirect following: a chain of 301/302 (relative and absolute Location),
# 303 POST -> GET, method/body preservation on 307, loop exhaustion, and the
# max_redirects opt-out.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    while (my $c = $srv->accept) {
        my $l = <$c>;
        my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
        my %h;
        while (my $line = <$c>) {
            last if $line eq "\r\n";
            $h{lc $1} = $2 if $line =~ /^([^:]+):\s*(.*?)\r\n$/;
        }
        my $body = '';
        read($c, $body, $h{'content-length'}) if $h{'content-length'};

        my ($status, $extra, $out) = ('200 OK', '', '');
        if    ($p eq '/a')     { $status = '301 Moved';     $extra = "Location: /b\r\n" }
        elsif ($p eq '/b')     { $status = '302 Found';     $extra = "Location: $base/c\r\n" }
        elsif ($p eq '/c')     { $out = "landed $m" }
        elsif ($p eq '/see')   { $status = '303 See Other'; $extra = "Location: /done\r\n" }
        elsif ($p eq '/keep')  { $status = '307 Redirect';  $extra = "Location: /done\r\n" }
        elsif ($p eq '/done')  { $out = "done $m body=$body" }
        elsif ($p eq '/loop')  { $status = '302 Found';     $extra = "Location: /loop\r\n" }
        else                   { $out = "plain $m" }

        print $c "HTTP/1.1 $status\r\nContent-Type: text/plain\r\n$extra"
               . "Content-Length: " . length($out) . "\r\n"
               . "Connection: close\r\n\r\n$out";
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.2);

plan tests => 7;

my $ua = Fetch->new;

# ---- a 301 -> 302 -> 200 chain, mixing relative and absolute Location -----
{
    my $res = $ua->get("$base/a")->get;
    is($res->status,  200,         'redirect chain reaches 200');
    is($res->content, 'landed GET', 'followed through to the final resource');
}

# ---- 303 turns POST into a bodyless GET ----------------------------------
{
    my $res = $ua->post("$base/see", body => 'x=1')->get;
    is($res->content, 'done GET body=', '303 POST becomes GET, body dropped');
}

# ---- 307 preserves the method and body -----------------------------------
{
    my $res = $ua->post("$base/keep", body => 'x=1')->get;
    is($res->content, 'done POST body=x=1', '307 preserves method and body');
}

# ---- a redirect loop stops at max_redirects and returns the last response -
{
    my $res = $ua->get("$base/loop", max_redirects => 3)->get;
    is($res->status, 302, 'redirect loop stops at max_redirects');
    ok($res->is_redirect, 'returns the last redirect rather than looping forever');
}

# ---- max_redirects => 0 disables following -------------------------------
{
    my $res = $ua->get("$base/a", max_redirects => 0)->get;
    is($res->status, 301, 'max_redirects => 0 returns the redirect itself');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
