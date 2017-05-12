#!perl -T
use Test::More;

my @test = qw/ test1 test2 /;

plan tests => 1 + @test;

use Distributed::Process::LocalWorker;
my $t = new Distributed::Process::LocalWorker;

isa_ok($t, 'Distributed::Process::LocalWorker');
$t->result($_) foreach @test;

foreach ( $t->result() ) {
    my $s = shift @test;
    like($_, qr/\E$s$/);
}
