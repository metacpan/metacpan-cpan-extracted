#!perl
 
use common::sense;
use POE qw(Wheel::FollowTail);
use IPC::Transit::Router qw(config_trans route_trans);
use IPC::Transit::Test::Example qw(recur get_routes);
use Sys::Hostname;
use Moose::Autobox;
 
recur(repeat => 10, work => sub {
    say 're-configuring';
    config_trans(get_routes());
});

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                Filename => '/var/log/messages',
                InputEvent => 'got_log_line',
                ResetEvent => 'got_log_rollover',
            );
        },
        got_log_line => sub {
            my $m = {
                logline => $_[ARG0],
                hostname => hostname,
                source => 'logtail.pl',
            };
            route_trans($m);
            say "Log: $_[ARG0]";
        },
        got_log_rollover => sub {
            print "Log rolled over.\n";
        },
    }
);
 
POE::Kernel->run();
