use strict;
use warnings;
use Test::More;
use Future::Q;
use FindBin;
use lib ("$FindBin::Bin");
use testlib::Utils qw(newf init_warn_handler test_log_num);
use Try::Tiny;

init_warn_handler;

note("----- Reporting unhandled failure");
note("--- Dependent Futures methods:");
note("---   rejected subfutures are all considered 'handled',");
note("---   so be sure to use failed_futures() method if you are concerned.");
note("---   Nevertheless, if the dependent future fails and not handled, it will");
note("---   warn about all the failed subfutures.");

my @cases = (
    {label => "wait_all, some of the subfutures fail", warn_num => 0, code => sub {
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->wait_all(@sub);
        $sub[0]->fail("failure 0");
        $sub[1]->done();
        $sub[2]->fail("failure 2");
        $sub[3]->done();
        ok(!$wf->is_ready, "dependent future is not yet ready");
        $sub[4]->fail("failure 3");
        ok($wf->is_ready, "dependent future is ready.");
        ok(!$wf->failure, "... and it's resolved.");
    }},
    {label => "wait_all, all of the subfutures fail", warn_num => 0, code => sub {
        note("wait_all never fails us !!");
        my @sub = map { newf->fail("failure $_") } 1..5;
        my $wf = Future::Q->wait_all(@sub);
        ok($wf->is_ready, "dependent future is ready.");
        ok(!$wf->failure, "... and it's resolved.");
    }},
    {label => "wait_any, single done", warn_num => 0, code => sub {
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->wait_any(@sub);
        $sub[0]->done;
        ok($wf->is_ready, "dependent future is ready");
        ok(!$wf->failure, "... and it's resolved.");
    }},
    {label => "wait_any, single fail", warn_num => 2, code => sub {
        note("In this case, there are two warnings (about the depedent future and the failed subfuture.)");
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->wait_any(@sub);
        $sub[3]->fail("failure 3");
        ok($wf->is_ready, "dependent future is ready");
        is(scalar($wf->failure), "failure 3", "... and it's failed with 'failure 3'");
    }},
    {label => "wait_any, all immediate fail", warn_num => 6, code => sub {
        note("In this case, one warning for the dependent future and five for the subfutures.");
        my @sub = map { newf->fail("failure $_") } 1..5;
        my $wf = Future::Q->wait_any(@sub);
        ok($wf->is_ready, "dependent future is ready");
        like(scalar($wf->failure), qr/^failure/, "... and it's failed with one of the failures.");
    }},
    {label => "wait_any, all immediate fail, handled", warn_num => 0, code => sub {
        note("All the failed futures are considered handled if you handle the failed dependent future.");
        my @sub = map { newf->fail("failure $_") } 1..5;
        my $wf = Future::Q->wait_any(@sub);
        my $handled = 0;
        $wf->catch(sub {
            my $e = shift;
            $handled = 1;
            like($e, qr/^failure/, "failure message OK");
        });
        ok($handled, "failure handled.");
    }},
    {label => "needs_all, all done", warn_num => 0, code => sub {
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->needs_all(@sub);
        ok(!$wf->is_ready, "dependent future is not ready");
        $_->done foreach @sub;
        ok(!$wf->failure, "dependent future is success");
    }},
    {label => "needs_all, some done, single failure, not handled", warn_num => 1, code => sub {
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->needs_all(@sub);
        $wf->then(sub {
            fail('This should not be executed.');
        });
        $_->done foreach @sub[0..3];
        ok(!$wf->is_ready, "dependent future is not ready");
        $sub[4]->fail("failure 4");
        is(scalar($wf->failure), "failure 4", "failure message OK");
    }},
    {label => "needs_all, some done, single failure, handled", warn_num => 0, code => sub {
        my @sub = map { newf } 1..5;
        my $handled = 0;
        my $wf = Future::Q->needs_all(@sub);
        $wf->then(sub {
            fail("This should not be executed.");
        }, sub {
            my $e = shift;
            $handled = 1;
            is($e, "failure 4", "failure message OK");
            is(int($wf->failed_futures), 1, "1 failed futures");
        });
        ok(!$handled, "not handled yet");
        $_->done foreach @sub[0..3];
        $sub[4]->fail("failure 4");
        ok($handled, "handled");
    }},
    {label => "needs_all, immediate multiple failed futures, not handled", warn_num => 4, code => sub {
        note("One warning for the dependent future, three for the subfutures");
        my @sub = map { $_ <= 3 ? newf->fail("failure $_") : newf->done($_) } 1..5;
        my $wf = Future::Q->needs_all(@sub);
        is(scalar($wf->failure), "failure 1", "dependent future is failure. Message OK");
    }},
    {label => "needs_all, immediate multiple failed futures, handled", warn_num => 0, code => sub {
        my @sub = map { $_ <= 3 ? newf->fail("failure $_") : newf->done($_) } 1..5;
        my $wf = Future::Q->needs_all(@sub);
        my $handled = 0;
        $wf->catch(sub {
            my $e = shift;
            $handled = 1;
            is($e, "failure 1", "dependent future is failure. message OK");
            is(int($wf->pending_futures), 0, "no pending subfutures");
            is(int($wf->ready_futures), 5, "five ready subfutures");
            is(int($wf->failed_futures), 3, "three failed subfutures");
            is(int($wf->done_futures), 2, "two done subfutures");
            is(int($wf->cancelled_futures), 0, "no cancelled subfutures");
        });
        ok($handled, "handled");
    }},
    {label => "needs_any, some failed, single succeeded", warn_num => 0, code => sub {
        note("In this case, the failed subfutures are ignored because the dependent future succeeds.");
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->needs_any(@sub);
        ok(!$wf->is_ready, "depedent future is not ready");
        $sub[0]->fail("failure 0");
        $sub[1]->fail("failure 1");
        ok(!$wf->is_ready, "depedent future is still not ready");
        $sub[2]->done();
        ok(!$wf->failure, "dependent future is now success");
        is(int($wf->failed_futures), 2, "... though there are two failed subfutures.");
    }},
    {label => "needs_any, all failed, not handled, then() propagates only the failure of dependent future", warn_num => 1, code => sub {
        my @sub = map { newf } 1..5;
        my $wf = Future::Q->needs_any(@sub);
        $wf->then(sub {
            fail("this should not be executed");
        });
        $sub[$_]->fail("failure $_") foreach 0 .. $#sub;
        is(scalar($wf->failure), "failure 4", "failure message OK");
    }},
    {label => "needs_any, all failed, handled", warn_num => 0, code => sub {
        my @sub = map { newf } 1..5;
        my $handled = 0;
        my $wf = Future::Q->needs_any(@sub);
        $wf->then(sub {
            fail("this should not be executed");
        }, sub {
            my $e = shift;
            $handled = 1;
            is($e, "failure 4", "failure message OK");
            is(int($wf->failed_futures), 5, "five failed subfutures");
        });
        $sub[$_]->fail("failure $_") foreach 0 .. $#sub;
        ok($handled, "failure handled");
    }}
);


foreach my $case (@cases) {
    note("--- -- Try: $case->{label}");
    test_log_num($case->{code}, $case->{warn_num}, "$case->{label}: expected $case->{warn_num} warnings");
}

{
    note("------- Special conditional case: wait_any, mixed immediate done and immediate fail");
    my @logs = ();
    local $Future::Q::OnError = sub {
        push(@logs, shift);
    };
    foreach my $done_first (0, 1) {
        note("--- -- done_first: $done_first");
        my @sub = $done_first
            ? ((map { newf->done($_) } 1,2), (map { newf->fail("failure $_") } 1,2,3))
            : ((map { newf->fail("failure $_") } 1,2,3), (map { newf->done($_) } 1,2));
        @logs = ();
        my $wf = Future::Q->wait_any(@sub);
        ok($wf->is_ready, "dependent future is ready");
        is(int($wf->failed_futures), 3, "3 failed futures.");
        if(not $wf->failure) {
            note("dependent future is success.");
            undef $wf;
            is(int(@logs), 0, "no warnings");
        }else {
            note("dependent future is failure.");
            undef $wf;
            is(int(@logs), 4, "4 warnings. One for the dependent, three for the failed subfutures.");
        }
    }
}

done_testing();

