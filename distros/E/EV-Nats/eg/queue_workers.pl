#!/usr/bin/env perl
# Queue group workers — messages load-balanced across group members
use strict;
use warnings;
use EV;
use EV::Nats;

my $worker_id = shift // $$;
my $n_msgs    = shift // 10;

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "error: @_\n" },
    on_connect => sub {
        print "worker $worker_id connected\n";

        my $received = 0;

        # queue group subscription — only one worker in group gets each message
        $nats->subscribe('jobs.>', sub {
            my ($subject, $payload) = @_;
            $received++;
            print "worker $worker_id: [$subject] $payload (total: $received)\n";
        }, 'workers');

        # if first arg is 'produce', also publish jobs
        if ($worker_id eq 'produce') {
            my $sent = 0;
            my $t; $t = EV::timer 0.2, 0.05, sub {
                $nats->publish('jobs.task', "job-" . ++$sent);
                if ($sent >= $n_msgs) {
                    undef $t;
                    # give time for messages to arrive
                    my $done; $done = EV::timer 1, 0, sub {
                        undef $done;
                        print "produced $sent jobs, worker received $received\n";
                        $nats->disconnect;
                        EV::break;
                    };
                }
            };
        }
    },
);

EV::run;
