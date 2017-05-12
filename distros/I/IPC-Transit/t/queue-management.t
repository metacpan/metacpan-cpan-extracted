#!env perl

use strict;use warnings;
use Data::Dumper;

use lib '../lib';
use lib 'lib';
use Test::More tests => 16;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();

ok IPC::Transit::send(qname => $IPC::Transit::test_qname, message => { a => 'b/c' });
ok my $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $m->{a} eq 'b/c';

my $stats;
eval {
    ok $stats = IPC::Transit::stats();
};
ok not $@;

ok ref $stats eq 'ARRAY';
ok ref $stats->[0] eq 'HASH';
my $stat;
foreach (@$stats) {
    next unless $_->{qname} eq $IPC::Transit::test_qname;
    $stat = $_;
}
ok $stat;

foreach my $stat_field (qw/uid gid ctime mode qnum qname/) {
    ok defined $stat->{$stat_field};
}
