use strict;
use warnings;
use Test::More;
use Future;
use Future::Q;
use FindBin;
use lib $FindBin::RealBin;
use testlib::Utils qw(init_warn_handler newf test_log_num);

init_warn_handler;

note("--- cancel() on next_future returned by finally()");

test_log_num sub {
    note("--- invocant pending");
    my $f = newf;
    my $nf = $f->finally(sub {
        fail("callback should not be called");
    });
    ok $f->is_pending, "f is pending";
    ok $nf->is_pending, "nf is pending";
    $nf->cancel;
    ok $f->is_cancelled, "f is cancelled";
    ok $nf->is_cancelled, "nf is cancelled";
}, 0, "0 warning";

foreach my $case_invo (qw(immediate_done immediate_fail)) {
    note("--- invocant $case_invo, returned_future pending");
    test_log_num sub {
        my $f = $case_invo eq "immediate_fail" ? newf()->reject("orig") : newf()->fulfill("orig");
        my $called = 0;
        my $ret;
        my $nf = $f->finally(sub {
            $called++;
            return $ret = Future->new;
        });
        is $called, 1, "callback called once";
        ok $f->is_ready, "f is ready";
        ok !$ret->is_ready, "ret is pending";
        ok $nf->is_pending, "nf is pending";
        $nf->cancel;
        ok $ret->is_cancelled, "ret is cancelled";
    }, 0, "0 warning";

    ## In the case of "case_invo = immediate_fail, returned_future =
    ## pending, next_future = cancel", maybe the failure of
    ## invo_future should not be considered "handled". However,
    ## calling cancel() on next_future is basically a declaration of
    ## "we don't care the result of that operation, so stop it!". If
    ## that means they don't care whether the operation fails, then we
    ## should make the failure "handled" so that its warning message
    ## won't bother them.
}

done_testing;
