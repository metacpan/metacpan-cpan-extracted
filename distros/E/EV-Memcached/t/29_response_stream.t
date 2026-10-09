use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

my $value = "v\0\xff" x 20000;
my $srv = FakeMemcached->new(script => sub {
    my $c = FakeMemcached->accept(shift);
    my $get = $c->read_request or exit 0;
    my $body = pack('N', 0x01020304) . $value;
    my $packet = pack('C C n C C n N N N N',
        0x81, $get->[0], 0, 4, 0, 0, length($body), $get->[1], 0, 42) . $body;
    syswrite($c->sock, substr($packet, 0, 11)) == 11 or die "write: $!";
    select undef, undef, undef, 0.02;
    my $rest = substr($packet, 11);
    my $off = 0;
    while ($off < length $rest) {
        my $n = syswrite($c->sock, $rest, length($rest) - $off, $off);
        die "write: $!" unless $n;
        $off += $n;
    }
    my $stat = $c->read_request or exit 0;
    $c->respond(op => $stat->[0], opaque => $stat->[1], key => 'pid', value => '123');
    $c->respond(op => $stat->[0], opaque => $stat->[1], key => 'version', value => 'test');
    $c->respond(op => $stat->[0], opaque => $stat->[1]);
    my $hit = $c->read_request or exit 0;
    $c->read_request or exit 0;  # quiet miss
    $c->respond_hit(op => $hit->[0], opaque => $hit->[1], key => 'hit',
        value => $value, flags => 7, cas => 43);
    my $fence = $c->read_request or exit 0;
    $c->respond(op => $fence->[0], opaque => $fence->[1]);
    my $error = $c->read_request or exit 0;
    $c->respond(op => $error->[0], opaque => $error->[1], status => 4);
    my $probe = $c->read_request or exit 0;
    $c->respond(op => $probe->[0], opaque => $probe->[1]);
    sleep 2;
});

my ($get, $stats, $batch, $stat_error, $probe, @errors);
my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
    on_error => sub { push @errors, $_[0]; EV::break });
$mc->gets('hit', sub { $get = $_[0] });
$mc->stats(sub { $stats = $_[0] });
$mc->mgets(['hit', 'miss'], sub { $batch = $_[0] });
$mc->stats('unsupported', sub { $stat_error = $_[1] });
$mc->noop(sub { $probe = $_[0]; EV::break });
my $t = EV::timer 2, 0, sub { EV::break };
EV::run;

is_deeply($get, { value => $value, flags => 0x01020304, cas => 42 },
    'fragmented metadata response preserves binary data');
is_deeply($stats, { pid => '123', version => 'test' }, 'stats accumulate through the terminator');
is_deeply($batch, { hit => { value => $value, flags => 7, cas => 43 } },
    'multi-get preserves metadata and omits quiet misses');
is($stat_error, 'INVALID_ARGUMENTS', 'stats error reaches its callback');
is($probe, 1, 'subsequent command still works');
is_deeply(\@errors, [], 'no protocol errors in the response stream');
$mc->disconnect;
$srv->finish;
done_testing;
