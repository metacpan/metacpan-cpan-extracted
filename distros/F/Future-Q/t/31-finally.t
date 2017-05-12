use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Memory::Cycle;
use Future::Q;
use FindBin;
use lib $FindBin::RealBin;
use testlib::Utils qw(init_warn_handler newf is_immediate test_log_num);

init_warn_handler;

my %tested_case = ();

### Case element: state of invocant object
my @CASES_INVOCANT =
    qw(pending_done pending_fail pending_cancel
       immediate_done immediate_fail immediate_cancel);

### Case element: return value from the callback
my @CASES_RETURN =
    qw(normal die pending_done pending_fail pending_cancel
       immediate_done immediate_fail immediate_cancel);

foreach my $invo (@CASES_INVOCANT) {
    foreach my $ret (@CASES_RETURN) {
        $tested_case{"$invo,$ret"} = 0;
    }
}

sub test_finally_case {
    my ($case_invo, $case_ret, $num_warning, $code) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    note("--- Case: $case_invo, $case_ret");
    test_log_num $code, $num_warning, "expected $num_warning warnings";
    $tested_case{"$case_invo,$case_ret"}++;
}

sub create_return {
    my ($case_ret) = @_;
    my %switch = (
        normal => sub { "return\n" },
        die => sub { die "return\n" },
        pending_done => sub { newf },
        pending_fail => sub { newf },
        pending_cancel => sub { newf },
        immediate_done => sub { newf()->fulfill("return\n") },
        immediate_fail => sub { newf()->reject("return\n") },
        immediate_cancel => sub { newf()->cancel() },
    );
    return $switch{$case_ret}->();
}

sub set_future {
    my ($future, $case, @values) = @_;
    my %method_for = (
        immediate_done => "fulfill",
        immediate_fail => "reject",
        immediate_cancel => "cancel",
        pending_done => "fulfill",
        pending_fail => "reject",
        pending_cancel => "cancel",
    );
    my $method = $method_for{$case};
    if($method eq "cancel") {
        $future->$method();
    }else {
        $future->$method(@values);
    }
}

foreach my $case_invo (qw(pending_done immediate_done)) {
    foreach my $case_ret (qw(normal immediate_done immediate_cancel pending_done pending_cancel)) {
        test_finally_case $case_invo, $case_ret, 0, sub {
            my $f = is_immediate($case_invo) ? newf()->fulfill("orig") : newf;
            my $called = 0;
            my $ret;
            my $nf = $f->finally(sub {
                is scalar(@_), 0, "finally callback should receive no argument";
                ok wantarray, "finally callback should be called in list context";
                $called++;
                return $ret = create_return $case_ret;
            });
            if(!is_immediate $case_invo) {
                ok $f->is_pending, "f is pending";
                ok $nf->is_pending, "nf is pending";
                is $called, 0, "not called yet";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                $f->fulfill("orig");
            }
            is $called, 1, "called once";
            if(!is_immediate $case_ret) {
                ok $nf->is_pending, "nf is pending";
                ok $ret->is_pending, "ret is pending";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                memory_cycle_ok $ret, "no cyclic ref on ret";
                set_future $ret, $case_ret, "return\n";
            }
            ok $f->is_fulfilled, "f is fulfilled";
            ok $nf->is_fulfilled, "nf is fulfilled";
            is_deeply [$nf->get], ["orig"], "nf's value is orig";
            memory_cycle_ok $f, "no cyclic ref on f";
            memory_cycle_ok $nf, "no cyclic ref on nf";
        };
    }
    foreach my $case_ret (qw(die immediate_fail pending_fail)) {
        test_finally_case $case_invo, $case_ret, 1, sub {
            my $f = is_immediate($case_invo) ? newf()->fulfill("orig") : newf;
            my $called = 0;
            my $ret;
            my $nf = $f->finally(sub {
                is scalar(@_), 0, "finally callback should receive no argument";
                ok wantarray, "finally callback should be called in list context";
                $called++;
                return $ret = create_return $case_ret;
            });
            if(!is_immediate $case_invo) {
                ok $f->is_pending, "f is pending";
                ok $nf->is_pending, "nf is pending";
                is $called, 0, "not called yet";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                $f->fulfill("orig");
            }
            is $called, 1, "called once";
            if(!is_immediate $case_ret) {
                ok $nf->is_pending, "nf is pending";
                ok $ret->is_pending, "ret is pending";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                memory_cycle_ok $ret, "no cyclic ref on ret";
                set_future $ret, $case_ret, "return\n";
            }
            ok $f->is_fulfilled, "f is fulfilled";
            ok $nf->is_rejected, "nf is rejected";
            is_deeply [$nf->failure], ["return\n"], "nf's failure is 'return'";
            memory_cycle_ok $f, "no cyclic ref on f";
            memory_cycle_ok $nf, "no cyclic ref on nf";
        };
    }
}


foreach my $case_invo (qw(pending_fail immediate_fail)) {
    foreach my $case_ret (qw(normal immediate_done immediate_cancel pending_done pending_cancel)) {
        test_finally_case $case_invo, $case_ret, 1, sub {
            my $f = is_immediate($case_invo) ? newf()->reject("orig") : newf;
            my $called = 0;
            my $ret;
            my $nf = $f->finally(sub {
                is scalar(@_), 0, "finally callback should receive no argument";
                ok wantarray, "finally callback should be called in list context";
                $called++;
                return $ret = create_return $case_ret;
            });
            if(!is_immediate $case_invo) {
                ok $f->is_pending, "f is pending";
                ok $nf->is_pending, "nf is pending";
                is $called, 0, "not called yet";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                $f->reject("orig");
            }
            is $called, 1, "called once";
            if(!is_immediate $case_ret) {
                ok $nf->is_pending, "nf is pending";
                ok $ret->is_pending, "ret is pending";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                memory_cycle_ok $ret, "no cyclic ref on ret";
                set_future $ret, $case_ret, "return\n";
            }
            ok $f->is_rejected, "f is rejected";
            ok $nf->is_rejected, "nf is rejected";
            is_deeply [$nf->failure], ["orig"], "nf's failure is 'orig'";
            memory_cycle_ok $f, "no cyclic ref on f";
            memory_cycle_ok $nf, "no cyclic ref on nf";
        };
    }
    foreach my $case_ret (qw(die immediate_fail pending_fail)) {
        test_finally_case $case_invo, $case_ret, 1, sub {
            my $f = is_immediate($case_invo) ? newf()->reject("orig") : newf;
            my $called = 0;
            my $ret;
            my $nf = $f->finally(sub {
                is scalar(@_), 0, "finally callback should receive no argument";
                ok wantarray, "finally callback should be called in list context";
                $called++;
                return $ret = create_return $case_ret;
            });
            if(!is_immediate $case_invo) {
                ok $f->is_pending, "f is pending";
                ok $nf->is_pending, "nf is pending";
                is $called, 0, "not called yet";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                $f->reject("orig");
            }
            is $called, 1, "called once";
            if(!is_immediate $case_ret) {
                ok $nf->is_pending, "nf is pending";
                ok $ret->is_pending, "ret is pending";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                memory_cycle_ok $ret, "no cyclic ref on ret";
                set_future $ret, $case_ret, "return\n";
            }
            ok $f->is_rejected, "f is rejected";
            ok $nf->is_rejected, "nf is rejected";
            is_deeply [$nf->failure], ["return\n"], "nf's failure is 'return'";
            memory_cycle_ok $f, "no cyclic ref on f";
            memory_cycle_ok $nf, "no cyclic ref on nf";
        };
    }
}

foreach my $case_invo (qw(pending_cancel immediate_cancel)) {
    foreach my $case_ret (@CASES_RETURN) {
        test_finally_case $case_invo, $case_ret, 0, sub {
            my $f = is_immediate($case_invo) ? newf()->cancel() : newf;
            my $called = 0;
            my $ret;
            my $nf = $f->finally(sub {
                is scalar(@_), 0, "finally callback should receive no argument";
                ok wantarray, "finally callback should be called in list context";
                $called++;
                return $ret = create_return $case_ret;
            });
            if(!is_immediate $case_invo) {
                ok $f->is_pending, "f is pending";
                ok $nf->is_pending, "nf is pending";
                is $called, 0, "not called yet";
                memory_cycle_ok $f, "no cyclic ref on f";
                memory_cycle_ok $nf, "no cyclic ref on nf";
                $f->cancel();
            }
            is $called, 0, "not called";
            ok $f->is_cancelled, "f is cancelled";
            ok $nf->is_cancelled, "nf is cancelled";
            memory_cycle_ok $f, "no cyclic ref on f";
            memory_cycle_ok $nf, "no cyclic ref on nf";
        };
    }
}


note("--- check if untested cases exist.");
foreach my $key (sort {$a cmp $b} keys %tested_case) {
    is($tested_case{$key}, 1, "Case $key is tested once.");
}



note("--- it should accept plain Future (not Future::Q) as returned_future");
test_finally_case "pending_done", "pending_done", 0, sub {
    my $f = newf;
    my $ret;
    my $called = 0;
    my $nf = $f->finally(sub {
        $called++;
        return $ret = Future->new;
    });
    is $called, 0, "not called yet";
    ok $nf->is_pending, "nf is pending";
    $f->fulfill("orig");
    is $called, 1, "called";
    ok $nf->is_pending, "nf is still pending";
    $ret->done("return");
    ok $nf->is_fulfilled, "nf is fulfilled";
    is_deeply [$nf->get], ["orig"], "nf's value is orig";
};
test_finally_case "pending_done", "pending_fail", 1, sub {
    my $f = newf;
    my $ret;
    my $called = 0;
    my $nf = $f->finally(sub {
        $called++;
        return $ret = Future->new;
    });
    is $called, 0, "not called yet";
    ok $nf->is_pending, "nf is pending";
    $f->fulfill("orig");
    is $called, 1, "called";
    ok $nf->is_pending, "nf is still pending";
    $ret->fail("return");
    ok $nf->is_rejected, "nf is rejected";
    is_deeply [$nf->failure], ["return"], "nf's failure is 'return'";
};




done_testing;

