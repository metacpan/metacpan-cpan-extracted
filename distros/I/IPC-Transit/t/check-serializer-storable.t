#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 35;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
ok IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => 'b' }, serializer => 'storable');
ok my $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $m->{a} eq 'b';

for(1..10) {
    ok IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => $_ }, serializer => 'storable');
}
foreach my $ct (1..10) {
    ok my $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
    ok $m->{a} == $ct;
}
