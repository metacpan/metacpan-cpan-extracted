#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();

my $iteration = 30000;
foreach my $serializer ('json', 'storable', 'dumper') {
    my $start_ts = time;
    foreach my $ct (1..$iteration) {
        IPC::Transit::send(
            qname => $IPC::Transit::test_qname,
            message => { a => $ct },
            serializer => $serializer,
            compression => 'none');
        ok my $ret = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
        die "On count $ct but received $ret->{a}"
            if $ct != $ret->{a};
    }
    my $run_time = time - $start_ts;
    my $messages_per_second = int($iteration / $run_time)
        if $run_time;
    my $message_per_second = 'infinite!'
        unless $run_time;
    ok 1, "serializer $serializer handled $messages_per_second messages per second";
}
done_testing();
