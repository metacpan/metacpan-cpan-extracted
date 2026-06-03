#!/usr/bin/env perl
# Rich worker errors via WORK_EXCEPTION.
#
# By default a worker that die()s sends WORK_FAIL and the client just
# sees ($result=undef, $err="job failed") — no detail. Turn on the
# "exceptions" option (here via the constructor on BOTH ends) and:
#
#   * a sync worker's die message is forwarded as a WORK_EXCEPTION
#     before the terminal failure, and
#   * an async worker can call $job->exception($payload) explicitly
#     to ship structured error detail.
#
# The client receives it through the on_exception handler; the terminal
# callback still fires with $err = "exception".
use strict;
use warnings;
use EV;
use EV::Gearman;

my $cli = EV::Gearman->new(host => '127.0.0.1', port => 4730, exceptions => 1);
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => 4730, exceptions => 1);

# Sync worker: a plain die() becomes a WORK_EXCEPTION carrying the
# message, then the job fails.
$wkr->register_function('parse::strict' => sub {
    my $job = shift;
    die "ParseError: unexpected token near '" . $job->workload . "'\n";
});
$wkr->work;

$cli->submit_job('parse::strict', '<<<bad', {
    on_exception => sub {
        warn "[client] on_exception: $_[0]";    # the die message
    },
}, sub {
    my ($result, $err) = @_;
    warn "[client] terminal: result=", ($result // 'undef'),
         " err=", ($err // 'undef'), "\n";       # err = "exception"
    EV::break;
});

my $guard = EV::timer 5, 0, sub { warn "timeout\n"; EV::break };
EV::run;
