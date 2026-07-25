# Admin/text protocol error delivery and multi-line commands:
#  - a single-line "ERR ..." reply (e.g. an unknown command) must be
#    delivered as the error argument, not as a successful result, and
#    the connection must survive;
#  - 'show jobs' / 'show unique jobs' are ".\n"-terminated multi-line
#    commands (verified against gearmand 1.1.21): the callback must
#    receive the complete body, and the connection must stay usable —
#    pre-fix the leftover lines were parsed as later replies, desynced
#    the stream and tore the connection down.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

sub run_with_timeout {
    my ($t, $why) = @_;
    my $w = EV::timer $t, 0, sub { fail("timeout: $why"); EV::break };
    EV::run;
}

my $g = EV::Gearman->new(host => $host, port => $port);

# ===== ERR reply is an error, not a success =====
my ($res, $err);
$g->admin('definitely_not_a_command', sub { ($res, $err) = @_; EV::break });
run_with_timeout 3, 'unknown admin command';
is $res, undef, 'unknown command: result is undef';
like $err, qr/^ERR /, 'unknown command: raw ERR text delivered as the error';
ok $g->is_connected, 'connection survives an admin ERR reply';

# the connection must still answer binary requests
my ($echo, $eerr);
$g->echo('still-up', sub { ($echo, $eerr) = @_; EV::break });
run_with_timeout 3, 'echo after admin ERR';
is $eerr, undef, 'echo after ERR: no error';
is $echo, 'still-up', 'echo after ERR: connection fully usable';

# ===== 'show jobs' is multi-line and does not corrupt the session =====
my $cli  = EV::Gearman->new(host => $host, port => $port);
my $func = "showjobs_$$";

# queue two background jobs (no worker) so the reply has known content
my @handles;
$cli->submit_job_bg($func, 'one', { unique => "sj1-$$" },
    sub { push @handles, $_[0]; EV::break if @handles == 2 });
$cli->submit_job_bg($func, 'two', { unique => "sj2-$$" },
    sub { push @handles, $_[0]; EV::break if @handles == 2 });
run_with_timeout 3, 'bg submissions';
is scalar(@handles), 2, 'both background jobs accepted';

my ($jobs, $jerr);
$g->admin('show jobs', sub { ($jobs, $jerr) = @_; EV::break });
run_with_timeout 3, 'show jobs';
is $jerr, undef, 'show jobs: no error';
ok defined $jobs, 'show jobs: got a body';
ok index($jobs, $handles[0]) >= 0 && index($jobs, $handles[1]) >= 0,
    'show jobs: complete multi-line body (both queued handles present)';

# 'show unique jobs' likewise
my ($uniq, $uerr);
$g->admin('show unique jobs', sub { ($uniq, $uerr) = @_; EV::break });
run_with_timeout 3, 'show unique jobs';
is $uerr, undef, 'show unique jobs: no error';
like $uniq, qr/sj1-$$/, 'show unique jobs: complete body lists our unique key';

# the following binary request on the same connection is the assertion
# that fails pre-fix (desync -> disconnect -> croak / "disconnected")
my ($e2, $eerr2);
eval { $g->echo('after-show-jobs', sub { ($e2, $eerr2) = @_; EV::break }) };
is $@, '', 'echo after show jobs did not croak';
run_with_timeout 3, 'echo after show jobs';
is $eerr2, undef, 'echo after show jobs: no error';
is $e2, 'after-show-jobs', 'binary echo still works on the same connection';
ok $g->is_connected, 'connection still up after multi-line admin command';

# ===== an argument-bearing 'show jobs' stays single-line (ERR) =====
my ($sx, $sxerr);
$g->admin('show jobs extra', sub { ($sx, $sxerr) = @_; EV::break });
run_with_timeout 3, 'show jobs with args';
is $sx, undef, 'show jobs with args: result is undef';
like $sxerr, qr/^ERR /, 'show jobs with args: ERR delivered as error';

done_testing;
