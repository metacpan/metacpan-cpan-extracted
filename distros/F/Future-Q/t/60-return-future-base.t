use strict;
use warnings;
use Future::Q;
use Future;
use FindBin;
use lib "$FindBin::RealBin";
use testlib::Utils qw(newf init_warn_handler test_log_num is_immediate);
use Test::More;

note("--- tests where the base Future object is returned from then() callback");

init_warn_handler();

note("--- done cases");
foreach my $tense (qw(immediate pending)) {
    my $case = "${tense}_done";
    test_log_num sub {
        note("--- -- return_future is $case");
        my $pf = newf;
        my $rf;
        my $cf = $pf->then(sub {
            $rf = Future->new;
            $rf->done("result") if is_immediate($case);
            return $rf;
        });
        isa_ok($cf, "Future::Q");
        $pf->fulfill();
        if(!is_immediate($case)) {
            ok($cf->is_pending, "cf is pending");
            $rf->done("result");
        }
        ok($cf->is_fulfilled, "cf is fulfilled");
        is(scalar($cf->get), "result", "cf result OK");
    }, 0, "no warning";
}

note("--- fail cases");
foreach my $tense (qw(immediate pending)) {
    my $case = "${tense}_fail";
    test_log_num sub {
        note("--- -- return_future is $case");
        my $pf = newf;
        my $rf;
        my $cf = $pf->then(sub {
            $rf = Future->new;
            $rf->fail("failure") if is_immediate($case);
            return $rf;
        });
        isa_ok($cf, "Future::Q");
        $pf->fulfill();
        if(!is_immediate($case)) {
            ok($cf->is_pending, "cf is pending");
            $rf->fail("failure");
        }
        ok($cf->is_rejected, "cf is rejected");
        is(scalar($cf->failure), "failure", "cf failure OK");
    }, 1, "1 warning for not handling the failure of cf";
}

note("--- cancel cases");
foreach my $tense (qw(immediate pending)) {
    my $case = "${tense}_cancel";
    test_log_num sub {
        note("--- -- return_future is $case");
        my $pf = newf;
        my $rf;
        my $cf = $pf->then(sub {
            $rf = Future->new;
            $rf->cancel() if is_immediate($case);
            return $rf;
        });
        isa_ok($cf, "Future::Q");
        $pf->fulfill();
        if(!is_immediate($case)) {
            ok($cf->is_pending, "cf is pending");
            $rf->cancel();
        }
        ok($cf->is_cancelled, "cf is cancelled");
    }, 0, "no warning";
}

done_testing();
