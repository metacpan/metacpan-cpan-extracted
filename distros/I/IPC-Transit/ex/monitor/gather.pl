#!perl

use common::sense;
use IPC::Transit;
use IPC::Transit::Router qw(config_trans route_trans);
use IPC::Transit::Test::Example qw(recur get_routes);
use File::Slurp;
use Moose::Autobox;
use Sys::Hostname;

config_trans(get_routes());

recur(repeat => 5, work => sub {
    my $text = read_file('/proc/loadavg') or die 'nothing in /proc/loadavg';
    if($text =~ /^.*?\s+.*?\s+.*?\s+(?<in_run_queue>\d+)\/(?<total_procs>\d+)/){
        route_trans(%+->merge({hostname => hostname, source => 'gather.pl'}));
    } else {
        die 'regex match failed';
    }
    say 'sent metric';
});

recur(repeat => 10, work => sub {
    say 're-configuring';
    config_trans(get_routes());
});

POE::Kernel->run();

__END__

1.36 1.14 0.79 2/385 6792
2/385 number of processes in run queue / total number of procs

