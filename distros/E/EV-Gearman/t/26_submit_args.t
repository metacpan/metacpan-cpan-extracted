# Argument-shape handling for submit_job* / register_function:
#  - an explicit undef in the opts slot means "no opts"; the trailing
#    callback is still honoured (it used to be silently dropped,
#    submitting the job with no callback and hanging the caller);
#  - any other unrecognised trailing argument croaks loudly;
#  - undef function name / workload croaks instead of warning and
#    submitting an empty string.
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

my $func = "argshape_$$";
my $wkr = EV::Gearman->new(host => $host, port => $port);
$wkr->register_function($func => sub { my $j = shift; return "echo:" . $j->workload });
$wkr->work;

my $cli = EV::Gearman->new(host => $host, port => $port);

# ===== the four shapes must all deliver the callback =====
my @got;
my $want = 4;
my $cb_for = sub {
    my $tag = shift;
    return sub { push @got, [$tag, $_[0], $_[1]]; EV::break if @got == $want };
};
$cli->submit_job($func, "plain", $cb_for->('plain'));
$cli->submit_job($func, "undefopts", undef, $cb_for->('undefopts'));
$cli->submit_job($func, "emptyhash", {}, $cb_for->('emptyhash'));
$cli->submit_job($func, "hash", { unique => "u-$func" }, $cb_for->('hash'));
my $guard = EV::timer 5, 0, sub { fail 'submit callback timeout'; EV::break };
EV::run;

is scalar(@got), 4, 'all four submission shapes fired their callback';
my %by_tag = map { $_->[0] => $_ } @got;
for my $tag (qw(plain undefopts emptyhash hash)) {
    ok $by_tag{$tag}, "$tag: callback fired";
    is $by_tag{$tag}[2], undef, "$tag: no error" if $by_tag{$tag};
}
is $by_tag{undefopts}[1], 'echo:undefopts',
    'explicit undef opts: result delivered to the trailing callback';

# ===== garbage trailing arguments croak loudly =====
eval { $cli->submit_job($func, "x", 'garbage', sub {}) };
like $@, qr/submit_job: unexpected argument 'garbage'/,
    'non-ref opts slot croaks, naming the value';

eval { $cli->submit_job($func, "x", sub {}, 'extra') };
like $@, qr/unexpected argument 'extra'/, 'trailing garbage after cb croaks';

eval { $cli->submit_job($func, "x", sub {}, { unique => 'z' }) };
like $@, qr/unexpected argument HASH reference/,
    'reversed (cb, \%opts) order croaks instead of silently dropping opts';

eval { $cli->submit_job($func, "x", 'garbage') };
like $@, qr/unexpected argument/, 'lone garbage arg croaks';

# ===== undef func / workload croak instead of warning =====
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    eval { $cli->submit_job(undef, "x", sub {}) };
    like $@, qr/function name required/, 'undef function name croaks';
    eval { $cli->submit_job($func, undef, sub {}) };
    like $@, qr/workload must be defined/, 'undef workload croaks';
    eval { $cli->submit_job_epoch($func, undef, time() + 60, sub {}) };
    like $@, qr/workload must be defined/, 'undef epoch workload croaks';
    is scalar(@w), 0, 'no uninitialized warnings emitted';
}

# ===== register_function: same undef-opts tolerance =====
# (A fresh worker connection: gearmand 1.1.21 does not NOOP a
# PRE_SLEEP-ing worker that CAN_DOs a function with an already-queued
# job, so registering a brand-new function mid-sleep would hang the
# submit — a server quirk, not what this test is about.)
my $func2 = "argshape2_$$";
my $wkr2  = EV::Gearman->new(host => $host, port => $port);
eval { $wkr2->register_function($func2, undef, sub { my $j = shift; return "two:" . $j->workload }) };
is $@, '', 'register_function($name, undef, $cb) accepted';
$wkr2->work;

my ($r2, $e2);
$cli->submit_job($func2, "wl", sub { ($r2, $e2) = @_; EV::break });
$guard = EV::timer 5, 0, sub { fail 'undef-opts register timeout'; EV::break };
EV::run;
is $e2, undef, 'no error from undef-opts registered function';
is $r2, 'two:wl', 'undef-opts registered function served the job';

# register_function misuse stays loud
eval { $wkr->register_function('no_cb_'.$$) };
like $@, qr/callback required/, 'register_function without cb croaks';
eval { $wkr->register_function('bad_'.$$, 'not-a-coderef') };
like $@, qr/unexpected argument 'not-a-coderef'/,
    'register_function with garbage arg croaks accurately';

done_testing;
