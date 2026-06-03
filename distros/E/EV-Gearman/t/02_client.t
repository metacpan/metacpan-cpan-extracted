use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
unless ($probe) {
    plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)";
}
close $probe;

sub run_with_timeout {
    my ($t, $why) = @_;
    my $w = EV::timer $t, 0, sub { fail("timeout: $why"); EV::break };
    EV::run;
}

my $cli = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port);

# Worker that reflects the workload
$wkr->register_function('test_reflect_'.$$ => sub {
    my $j = shift;
    return $j->workload;
});
# Worker that fails
$wkr->register_function('test_fail_'.$$ => sub { die "intentional failure\n" });
# Worker that emits intermediate events
$wkr->register_function('test_events_'.$$ => sub {
    my $j = shift;
    $j->send_data("data-1");
    $j->warning("a warning");
    $j->status(1, 2);
    $j->send_data("data-2");
    return "result-bytes";
});
$wkr->work;

# Foreground simple
my ($r, $e);
$cli->submit_job('test_reflect_'.$$, "abc", sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'reflect';
is $r, 'abc', 'foreground reflect: result correct';
is $e, undef, 'foreground reflect: no error';

# Foreground with binary payload (NULs)
my $payload = "a\0b\0c\0\0";
($r, $e) = (undef, undef);
$cli->submit_job('test_reflect_'.$$, $payload, sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'binary';
is $r, $payload, 'binary payload preserved';

# Foreground that fails
($r, $e) = (undef, undef);
$cli->submit_job('test_fail_'.$$, "x", sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'fail';
ok !defined($r), 'fail: no result';
ok defined($e), 'fail: got error';

# Foreground with on_data / on_warning / on_status
my @data; my @warns; my @statuses;
($r, $e) = (undef, undef);
$cli->submit_job('test_events_'.$$, "ignored", {
    on_data    => sub { push @data, $_[0] },
    on_warning => sub { push @warns, $_[0] },
    on_status  => sub { push @statuses, [@_] },
}, sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'events';
is_deeply \@data, ['data-1', 'data-2'], 'on_data fired in order';
is_deeply \@warns, ['a warning'], 'on_warning fired';
is_deeply $statuses[0], ['1', '2'], 'on_status num/denom';
is $r, 'result-bytes', 'completion result delivered after events';
is $e, undef, 'no error after events';

# Background submission gets a handle
($r, $e) = (undef, undef);
$cli->submit_job_bg('test_reflect_'.$$, "bg", sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'bg';
ok defined($r) && length($r) > 0, "got handle: $r";
is $e, undef, 'bg: no error';

# get_status on the bg handle (job has finished, may report unknown)
my $info;
$cli->get_status($r, sub { ($info) = @_; EV::break });
run_with_timeout 5, 'get_status';
ok ref($info) eq 'HASH', 'got status hashref';
ok exists $info->{handle}, 'has handle';
ok exists $info->{known}, 'has known';
ok exists $info->{running}, 'has running';

# get_status_unique uses STATUS_RES_UNIQUE which has 6 fields incl client_count
my $unique_key = "uk-$$";
$cli->submit_job_bg('test_reflect_'.$$, "uniq-payload",
    { unique => $unique_key }, sub {});
my $u_info;
$cli->get_status_unique($unique_key, sub { ($u_info) = @_; EV::break });
run_with_timeout 5, 'get_status_unique';
ok ref($u_info) eq 'HASH', 'got unique status hashref';
ok exists $u_info->{unique}, 'has unique';
ok exists $u_info->{known}, 'has known';
ok exists $u_info->{client_count}, 'has client_count';

done_testing;
