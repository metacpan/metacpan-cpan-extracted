#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 10;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
ok IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => 'b' });
ok my $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $m->{a} eq 'b';
ok $m->{'.ipc_transit_meta'};
ok ref $m->{'.ipc_transit_meta'};
ok ref $m->{'.ipc_transit_meta'} eq 'HASH';
ok $m->{'.ipc_transit_meta'}->{send_ts};
ok $m->{'.ipc_transit_meta'}->{send_ts} =~ /^\d+$/;
