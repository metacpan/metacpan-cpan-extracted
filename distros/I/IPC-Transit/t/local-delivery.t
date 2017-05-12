#!env perl
use strict;use warnings;

use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Test::More tests => 36;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

my $q = 'test_local_queue';
ok IPC::Transit::local_queue(qname => $q);
IPC::Transit::send(qname => $q, message => { a => 'b' });
ok IPC::Transit::stat(qname => $q)->{qnum} == 1;
ok my $m = IPC::Transit::receive(qname => $q)->{a} eq 'b';
ok IPC::Transit::stat(qname => $q)->{qnum} == 0;
for(1..10) {
    ok IPC::Transit::send(qname => 'test_local_queue', message => { a => $_ });
}
foreach my $ct (1..10) {
    ok my $m = IPC::Transit::receive(qname => 'test_local_queue');
    ok $m->{a} == $ct;
}

__END__
IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => $_ });
IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => $_ });
print Dumper IPC::Transit::stat(qname => $IPC::Transit::test_qname);

system 'ipcs -a -q | tail';
