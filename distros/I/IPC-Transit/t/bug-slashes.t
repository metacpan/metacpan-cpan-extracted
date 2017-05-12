#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 5;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
ok IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => 'b/c' });
ok my $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $m->{a} eq 'b/c';
