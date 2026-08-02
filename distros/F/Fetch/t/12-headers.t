#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;
use Fetch::Headers;

# Fetch::Headers: the object API in isolation, then over the wire - response
# headers come back as a Fetch::Headers (with multi-valued get_all), and
# request headers may be given as a hashref, an arrayref of pairs, or a
# Fetch::Headers, with repeated names preserved.

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
                my @req;
                while (my $h = <$c>) { last if $h eq "\r\n"; push @req, $h }
                my @tr = map { /^X-Trace:\s*(.*?)\r/i ? $1 : () } @req;
                my $b  = 'traces=' . join(',', @tr);
                print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                       . "Set-Cookie: a=1\r\nSet-Cookie: b=2\r\n"
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

plan tests => 19;

# ---- unit: the container -------------------------------------------------
{
    my $h = Fetch::Headers->new(Accept => 'text/html', 'X-A' => '1');
    is($h->get('accept'), 'text/html', 'get is case-insensitive');
    $h->add('X-A' => '2');
    is_deeply([ $h->get_all('x-a') ], [ '1', '2' ], 'get_all keeps every value');
    $h->set('X-A' => '9');
    is_deeply([ $h->get_all('x-a') ], [ '9' ], 'set replaces all values');
    ok($h->exists('Accept'), 'exists is case-insensitive');
    $h->remove('accept');
    ok(!$h->exists('Accept'), 'remove drops the field');
    is_deeply([ $h->pairs ], [ 'X-A', '9' ], 'pairs yields the flat list');

    is(Fetch::Headers->new({ A => 'b' })->get('a'), 'b', 'built from hashref');
    is(Fetch::Headers->new([ A => 'b' ])->get('a'), 'b', 'built from arrayref');
    isa_ok($h->clone, 'Fetch::Headers', 'clone');

    my $m = Fetch::Headers->new(A => '1', B => '2');
    $m->merge({ B => '9', C => '3' });
    is($m->get('b'), '9', 'merge overrides an existing field');
    is($m->get('a'), '1', 'merge keeps untouched fields');
    is($m->get('c'), '3', 'merge adds new fields');
}

# ---- over the wire -------------------------------------------------------
my $ua = Fetch->new;

{
    my $res = $ua->get("$base/")->get;
    isa_ok($res->headers, 'Fetch::Headers', 'response headers object');
    is_deeply([ $res->headers->get_all('set-cookie') ], [ 'a=1', 'b=2' ],
        'repeated Set-Cookie preserved via get_all');
    is(scalar(@{ $res->headers }), 10, 'still an arrayref underneath (5 fields)');
    is($res->header('content-type'), 'text/plain', 'header() delegates to get');
}

is($ua->get("$base/", headers => { 'X-Trace' => 'h' })->get->content,
    'traces=h', 'request headers from a hashref');
is($ua->get("$base/", headers => [ 'X-Trace' => 'a', 'X-Trace' => 'b' ])->get->content,
    'traces=a,b', 'request headers from an arrayref keep both values');
{
    my $H = Fetch::Headers->new;
    $H->add('X-Trace' => 'x');
    $H->add('X-Trace' => 'y');
    is($ua->get("$base/", headers => $H)->get->content,
        'traces=x,y', 'request headers from a Fetch::Headers');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
