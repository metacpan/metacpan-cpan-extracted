#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# access_log_format: Apache directives compiled once, the json shape, the
# default byte-identical to the Combined line, an unknown directive refused
# before the fork; error_log: the server's own messages in a file.

my $dir = File::Temp::tempdir(CLEANUP => 1);
my ($pa, $pb, $pc) = free_ports(3);
plan skip_all => "no free loopback port" unless $pa && $pb && $pc;

my $app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'hello' ] ] if $env->{PATH_INFO} eq '/hi';
    return [ 204, [], [] ] if $env->{PATH_INFO} eq '/empty';
    die "handler died on purpose\n" if $env->{PATH_INFO} eq '/die';
    [ 404, [ 'Content-Type' => 'text/plain' ], [ 'nope' ] ];
};

my %pid;
sub spawn {
    my ($port, %opt) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1, %opt);
        exit 0;
    }
    $pid{$port} = $pid;
}
spawn($pa, access_log => "$dir/a.log",
          access_log_format => '%h %>s %b "%{X-Test}i" %D %q %U %m %H %P %%');
spawn($pb, access_log => "$dir/b.log", access_log_format => 'json',
          error_log => "$dir/err.log");
spawn($pc, access_log => "$dir/c.log");

sub get {
    my ($port, $path, @hdrs) = @_;
    my $s;
    for (1 .. 50) {
        $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") and last;
        Time::HiRes::sleep(0.1);
    }
    return '' unless $s;
    $s->syswrite("GET $path HTTP/1.1\r\nHost: t\r\nConnection: close\r\n"
               . join('', map { "$_\r\n" } @hdrs) . "\r\n");
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c }
        alarm 0;
    };
    close $s;
    return $buf;
}

sub lines {
    my ($file, $want) = @_;
    my @l;
    for (1 .. 50) {
        if (open my $fh, '<', $file) { @l = <$fh>; chomp @l; }
        last if @l >= $want;
        Time::HiRes::sleep(0.1);
    }
    return @l;
}

# ---- a custom format -----------------------------------------------------
{
    like get($pa, '/hi?x=1&y=2', 'X-Test: a"b\\c'), qr/^HTTP\/1\.1 200/, 'server A answers';
    get($pa, '/empty');
    my @l = lines("$dir/a.log", 2);
    is scalar @l, 2, 'two lines logged in the custom format';
    like $l[0], qr/\A127\.0\.0\.1 200 5 "a\\"b\\\\c" \d+ \?x=1&y=2 \/hi GET HTTP\/1\.1 \d+ %\z/,
        'every directive rendered: host, status, bytes, escaped header, duration, query, path, method, protocol, pid, percent';
    like $l[1], qr/\A127\.0\.0\.1 204 0 "-" \d+  \/empty GET HTTP\/1\.1 \d+ %\z/,
        'an absent header is "-", an empty query is nothing, a bodyless 204 counts 0';
}

# ---- json, and the error log --------------------------------------------
{
    like get($pb, '/hi', 'User-Agent: ua"1', 'Referer: http://r/'), qr/200/, 'server B answers';
    like get($pb, '/die'), qr/^HTTP\/1\.1 500/, 'a dying handler is a 500 on server B';
    my @l = lines("$dir/b.log", 2);
    is scalar @l, 2, 'two JSON lines';
    require JSON::PP;
    my $o = eval { JSON::PP->new->decode($l[0]) };
    ok $o, 'the first line decodes as JSON' or diag $l[0];
    is $o->{status}, 200, 'status is a number';
    is $o->{bytes}, 5, 'bytes is a number';
    is $o->{method}, 'GET', 'method';
    is $o->{uri}, '/hi', 'uri';
    is $o->{user_agent}, 'ua"1', 'the quote in the User-Agent was escaped and decodes back';
    is $o->{referer}, 'http://r/', 'referer';
    is $o->{remote_addr}, '127.0.0.1', 'remote_addr';
    is $o->{user}, '', 'an absent value is an empty string';
    like $o->{time}, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d{4}\z/, 'time is ISO 8601';
    ok defined $o->{duration_us} && $o->{duration_us} >= 0, 'duration_us is present';
    my $e = eval { JSON::PP->new->decode($l[1]) };
    is $e->{status}, 500, 'the 500 was logged';
    my @err = lines("$dir/err.log", 1);
    ok scalar @err, 'the error log has a line';
    like $err[0], qr/\A\[\d\d\/\w{3}\/\d{4}:\d\d:\d\d:\d\d [+-]\d{4}\] \[\d+\] Hyperman: application died: handler died on purpose\z/,
        'stamped with time and pid, and it names what died';
}

# ---- the default is the Combined line, byte for byte ----------------------
{
    get($pc, '/hi', 'User-Agent: curl/8', 'Referer: http://ref/');
    my @l = lines("$dir/c.log", 1);
    like $l[0], qr{\A127\.0\.0\.1 - - \[\d\d/\w{3}/\d{4}:\d\d:\d\d:\d\d [+-]\d{4}\] "GET /hi HTTP/1\.1" 200 5 "http://ref/" "curl/8"\z},
        'the default format is the Combined line the 0.56 writer produced';
}

# ---- an unknown directive is refused before the fork -----------------------
{
    my ($pd) = free_ports(1);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDERR, '>', "$dir/bad.err";
        open STDOUT, '>', '/dev/null';
        eval { Hyperman->run(app => $app, host => '127.0.0.1', port => $pd, workers => 1,
                             access_log => "$dir/d.log", access_log_format => '%h %Z') };
        print STDERR "CROAK: $@" if $@;
        exit 3;
    }
    waitpid $pid, 0;
    is $? >> 8, 3, 'run() returned (croaked) rather than serving';
    open my $fh, '<', "$dir/bad.err"; local $/; my $err = <$fh> // '';
    like $err, qr/access_log_format: unknown directive %Z/, '...naming the directive';
}

kill 'TERM', $_ for values %pid;
waitpid $_, 0 for values %pid;
done_testing;
