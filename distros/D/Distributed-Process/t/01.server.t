#!perl -T
use Test::More tests => 2;

use Distributed::Process::Server;
my $s = new Distributed::Process::Server -port => 8147;

isa_ok($s, 'Distributed::Process::Server');
is($s->port(), 8147);
