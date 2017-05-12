use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::RealBin";
use testlib::Utils qw(newf filter_callbacks is_immediate);
use Future::Q;
use Test::Memory::Cycle;

note("------ tests to cancel next_future of then");

{
    note("--- Case: pending invocant future");
    my $f = newf;
    my $nf = $f->then(sub {
        fail("this should not be executed.");
    }, sub {
        fail("this should not be executed.");
    });
    memory_cycle_ok($f, "f is free of cyclic ref");
    memory_cycle_ok($nf, "nf is free of cyclic ref");
    ok($f->is_pending, "f is pending");
    ok($nf->is_pending, "nf is pending");
    $nf->cancel();
    ok($nf->is_cancelled, "nf is cancelled");
    ok($f->is_cancelled, "If invocant future (f) is still pending, f is cancelled when nf is cancelled.");
    memory_cycle_ok($f, "f is still free of cyclic ref");
    memory_cycle_ok($nf, "nf is still free of cyclic ref");
}

foreach my $case (
    {invo => "immediate_done", arg => "on_done"},
    {invo => "immediate_done", arg => "both"},
    {invo => "pending_done", arg => "on_done"},
    {invo => "pending_done", arg => "both"},
    {invo => "immediate_fail", arg => "on_fail"},
    {invo => "immediate_fail", arg => "both"},
    {invo => "pending_fail", arg => "on_fail"},
    {invo => "pending_fail", arg => "both"},
){
    my $case_str = "$case->{invo},$case->{arg}";
    note("--- Case: $case_str -> pending returned future");
    my %switch_f = (
        immediate_done => sub { newf()->fulfill(1,2,3) },
        pending_done   => sub { newf() },
        immediate_fail => sub { newf()->reject(1,2,3) },
        pending_fail   => sub { newf() },
    );
    my $f = $switch_f{$case->{invo}}->();
    my $rf = newf;
    my $callbacked = 0;
    my $nf = $f->then(filter_callbacks $case->{arg}, sub {
        $callbacked++;
        return $rf;
    }, sub {
        $callbacked++;
        return $rf;
    });
    if(not is_immediate($case->{invo})) {
        ok($f->is_pending, "f is pending");
        ok($nf->is_pending, "nf is pending");
        memory_cycle_ok($f, "f is free of cyclic ref while pending");
        memory_cycle_ok($nf, "nf is free of cyclic ref while f is pending");
        if($case->{invo} eq "pending_done") {
            $f->fulfill(1,2,3);
        }elsif($case->{invo} eq "pending_fail") {
            $f->reject(1,2,3);
        }else {
            die "Unexpected case->invo: $case->{invo}";
        }
    }
    is($callbacked, 1, "callback executed once");
    ok($nf->is_pending, "nf is pending");
    ok($rf->is_pending, "rf is pending");
    memory_cycle_ok($f, "f is free of cyclic ref");
    memory_cycle_ok($nf, "nf is free of cyclic ref");
    memory_cycle_ok($rf, "rf is free of cyclic ref");
    $nf->cancel();
    ok($rf->is_cancelled, "If returned future (rf) is pending, rf is cancelled when nf is cancelled.");
    memory_cycle_ok($f, "f is still free of cyclic ref");
    memory_cycle_ok($nf, "nf is still free of cyclic ref");
    memory_cycle_ok($rf, "rf is still free of cyclic ref");
}


done_testing();


