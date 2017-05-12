use strict;
use warnings;
use Test::More;
use Test::Identity;
use Test::Memory::Cycle;
use Future;
use Future::Q;
use FindBin;
use lib "$FindBin::RealBin";
use testlib::Utils qw(newf init_warn_handler test_log_num);

init_warn_handler;

my @immediate_test_cases = (
    {label => "string", args => ["aaa"]},
    {label => "empty", args => []},
    {label => "undef", args => [undef]},
    {label => "multi", args => [1,2,3]},
    {label => "done Future", args => [Future->new->done(10,20)], exp_get => [10, 20]},
    {label => "failed Future", args => [Future->new->fail("hoge")], exp_fail => ["hoge"], exp_warn => 1},
    {label => "failed Future::Q", args => [Future::Q->new->reject("foo", "bar")],
     exp_fail => ["foo", "bar"], exp_warn => 1},
    {label => "cancelled Future", args => [Future->new->cancel()], exp_cancel => 1},
);

## I employ somewhat weird looping here, because simple for() loop or
## while(my $case = shift @imm...) loop seem to prolong the life time
## of objects in $case. To check the warning log, I need to destroy
## the $case at the end of test_log_num block.

while(@immediate_test_cases) {
    my $case = shift @immediate_test_cases;
    last if !$case;
    note("--- immediate $case->{label}");
    my $exp_warn = $case->{exp_warn} || 0;
    test_log_num sub {
        my $f = newf;
        note("f: $f");
        identical($f->resolve(@{$case->{args}}), $f, "$case->{label}: resolve() should return the object");
        memory_cycle_ok $f, "$case->{label}: no cyclic ref";
        my $exp_get = $case->{exp_get};
        my $exp_fail = $case->{exp_fail};
        if($case->{exp_cancel}) {
            ok $f->is_cancelled, "$case->{label}: f is cancelled";
        }elsif($exp_fail) {
            is_deeply([$f->failure], $exp_fail, "$case->{label}: resolve() rejects ok");
        }else {
            $exp_get ||= $case->{args};
            is_deeply([$f->get], $exp_get, "$case->{label}: resolve() fulfills ok");
        }
        undef $case;   ## to destroy futures
    }, $exp_warn, "$case->{label}: $exp_warn warnings";
}

{
    note("--- Future and other stuff");
    test_log_num sub {
        my $f = newf;
        my $given_f = Future->new->done();
        $f->resolve($given_f, 10, 20);
        is_deeply([$f->get], [$given_f, 10, 20], "get Future and other stuff. given Future is not expanded");
    }, 0, "no warning";
}

{
    note("--- pending done Future");
    test_log_num sub {
        my $f = newf;
        my $given_f = Future->new;
        identical($f->resolve($given_f), $f, "resolve should return the object");
        ok $f->is_pending, "f is still pending";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
        memory_cycle_ok $f, "no cyclic ref on f";
        $given_f->done(100);
        ok $f->is_fulfilled, "f is fulfilled";
        is_deeply [$f->get], [100], "... its values OK";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
        memory_cycle_ok $f, "no cyclic ref on f";
    }, 0, "no warning";
}

foreach my $given_class (qw(Future Future::Q)) {
    note("--- pending failed $given_class");
    test_log_num sub {
        my $f = newf;
        my $given_f = $given_class->new;
        identical($f->resolve($given_f), $f, "resolve should return the object");
        ok $f->is_pending, "f is still pending";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
        memory_cycle_ok $f, "no cyclic ref on f";
        $given_f->fail(200);
        ok $f->is_rejected, "f is rejected";
        is_deeply [$f->failure], [200], "... its values OK";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
        memory_cycle_ok $f, "no cyclic ref on f";
    }, 1, "1 warning from the resolve() invocant";
}

{
    note("--- pending cancelled Future");
    test_log_num sub {
        my $f = newf;
        my $given_f = Future->new;
        identical($f->resolve($given_f), $f, "resolve should return the object");
        ok $f->is_pending, "f is still pending";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
        memory_cycle_ok $f, "no cyclic ref on f";
        $given_f->cancel();
        ok $f->is_cancelled, "f is cancelled";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
        memory_cycle_ok $f, "no cyclic ref on f";
    }, 0, "no warning";
}

{
    note("--- cancel invocant future");
    test_log_num sub {
        my $f = newf;
        my $given_f = Future->new;
        identical($f->resolve($given_f), $f, "resolve should return the object");
        ok !$given_f->is_ready, "given_f is still pending";
        $f->cancel();
        ok $given_f->is_cancelled, "given_f is cancelled";
        memory_cycle_ok $f, "no cyclic ref on f";
        memory_cycle_ok $given_f, "no cyclic ref on given_f";
    }, 0, "no warning";
}

my @already_cancelled_test_cases = (
    {label => "values", args => ["hoge"]},
    {label => "immediate done Future", args => [Future->new->done]},
    {label => "immediate failed Future", args => [Future->new->fail("hoge")]},
    {label => "immediate failed Future::Q", args => [Future::Q->new->fail("hoge")], exp_warn => 1},
    {label => "immediate cancelled Future", args => [Future->new->cancel]},
);

while(@already_cancelled_test_cases) {
    my $case = shift @already_cancelled_test_cases;
    last if !$case;
    note("--- resolve() on already cancelled future: $case->{label}");
    my $exp_warn = $case->{exp_warn} || 0;
    test_log_num sub {
        my $f = newf;
        $f->cancel();
        $f->resolve(@{$case->{args}});
        ok $f->is_cancelled, "f is cancelled, of course";
        undef $case;  ## to destroy futures
    }, $exp_warn, "$case->{label}: $exp_warn warnings";
}

{
    note("--- resolve() on already cancelled future: pending failed Future::Q");
    test_log_num sub {
        my $f = newf;
        $f->cancel();
        my $given_f = newf;
        $f->resolve($given_f);

        ## Should $given_f be cancelled? That behavior is interesting
        ## but may be confusing.

        ok $given_f->is_pending, "given_f is still pending";
        ok $f->is_cancelled, "f is cancelled, of course";
        $given_f->reject("hoge");
        ok $f->is_cancelled, "f is cancelled, of course";
    }, 1, "1 warning from the given_f";
}

{
    note("--- resolve() chain");
    test_log_num sub {
        my @futures = map { newf } 1..4;
        $futures[$_]->resolve($futures[$_+1]) for 0..2;
        ok $futures[$_]->is_pending, "future $_ is pending" for 0..3;
        $futures[-1]->resolve("foobar");
        foreach my $i (0..3) {
            ok $futures[$i]->is_fulfilled, "future $i is fulfilled";
            is_deeply [$futures[$i]->get], ["foobar"], "... its values OK";
        }
    }, 0, "no warning";
}

done_testing;
