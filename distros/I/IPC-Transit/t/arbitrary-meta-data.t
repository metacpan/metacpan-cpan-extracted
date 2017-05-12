#!env perl

use strict;use warnings;
use Data::Dumper;

use lib '../lib';
use lib 'lib';
use Test::More tests => 14;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();

ok IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => 'b/c'}, x => { this => 'that'}, once => ['more',2]);
ok my $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $m->{a} eq 'b/c';
ok $m->{'.ipc_transit_meta'};
ok $m->{'.ipc_transit_meta'}->{x};
ok $m->{'.ipc_transit_meta'}->{x}->{this};
ok $m->{'.ipc_transit_meta'}->{x}->{this} eq 'that';

ok $m->{'.ipc_transit_meta'}->{once};
ok ref $m->{'.ipc_transit_meta'}->{once} eq 'ARRAY';
ok $m->{'.ipc_transit_meta'}->{once}->[0];
ok $m->{'.ipc_transit_meta'}->{once}->[0] eq 'more';
ok $m->{'.ipc_transit_meta'}->{once}->[1] == 2;
