# leak -*-perl-*-
use Test; plan test => 6;
use Event qw(all_watchers);

my @e = Event::all_watchers();
ok @e, 0;
@e = Event::all_idle();
ok @e, 0;

sub thrash {
    Event->idle(parked=>1)->cancel;
    Event->io(parked => 1)->cancel;
    Event->signal(parked=>1)->cancel;
    Event->timer(parked=>1)->cancel;
    my $var = 1;
    Event->var(parked=>1)->cancel;
}
for (1..2) { thrash(); }

my $got = join(', ', map { ref } all_watchers()) || 'None';
ok($got, 'None');

{
    my $io = Event->io(parked => 1);
    ok !$io->is_cancelled;
    $io->cancel for 1..3;  #shouldn't crash!
    ok $io->is_cancelled;
    eval { $io->start };
    ok $@, '/cancelled/';
}
