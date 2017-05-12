use strict;
use Test::More;
use Test::Requires 'threads';
use_ok "File::MMagic::XS";

my $x = File::MMagic::XS->new; 
my @threads;
for (1..5) {
    push @threads, threads->create(sub{
        note( "spawned thread : " . threads->tid() );
    });
}

foreach my $thr (@threads) {
    note( "joining thread : " . $thr->tid );
    $thr->join;
}

ok(1);
done_testing();