#!env perl
use strict;use warnings;

use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Test::More tests => 41;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

my $qname = 'test_local_queue';
IPC::Transit::send(qname => $qname, message => { nonlocal => 'q' });
{   my $stat = IPC::Transit::stat(qname => $qname);
    ok $stat->{qnum} == 1;
    ok $stat->{ctime};
}

ok IPC::Transit::local_queue(qname => $qname);
IPC::Transit::send(qname => $qname, message => { a => 'b' });
ok IPC::Transit::stat(qname => $qname)->{qnum} == 1;
ok my $m = IPC::Transit::receive(qname => $qname)->{a} eq 'b';
ok IPC::Transit::stat(qname => $qname)->{qnum} == 0;
for(1..10) {
    ok IPC::Transit::send(qname => $qname, message => { a => $_ });
}
foreach my $ct (1..10) {
    ok my $m = IPC::Transit::receive(qname => $qname);
    ok $m->{a} == $ct;
}

{   my $m = IPC::Transit::receive(qname => $qname, override_local => 1);
    ok $m->{nonlocal} eq 'q';
    my $stat = IPC::Transit::stat(qname => $qname, override_local => 1);
    ok $stat->{ctime};
    ok $stat->{qnum} == 0;
}
__END__
IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => $_ });
IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => $_ });
print Dumper IPC::Transit::stat(qname => $IPC::Transit::test_qname);

system 'ipcs -a -q | tail';
