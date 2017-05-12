use strict;
use warnings;
use Test::More;
use Test::Memory::Cycle;
use FindBin;
use lib "$FindBin::RealBin";
use testlib::Utils qw(newf init_warn_handler test_log_num filter_callbacks is_immediate isnt_identical);
use Test::Builder;
use Carp;

init_warn_handler();

my %tested_case = ();
### Case element: state of invocant object
my @CASES_INVOCANT =
    qw(pending_done pending_fail pending_cancel
       immediate_done immediate_fail immediate_cancel);

### Case element: arguments for then()
my @CASES_ARGS = qw(on_done on_fail both none);

### Case element: return value from the callback
my @CASES_RETURN =
    qw(normal die pending_done pending_fail pending_cancel
       immediate_done immediate_fail immediate_cancel);
    
foreach my $invo (@CASES_INVOCANT) {
    foreach my $arg (@CASES_ARGS) {
        foreach my $ret (@CASES_RETURN) {
            $tested_case{"$invo,$arg,$ret"} = 0;
        }
    }
}

sub test_then_case {
    my ($case_invo, $case_arg, $case_ret, $num_warning, $code) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    note("--- Case: $case_invo, $case_arg, $case_ret");
    test_log_num $code, $num_warning, "expected $num_warning warnings";
    $tested_case{"$case_invo,$case_arg,$case_ret"}++;
}

sub create_return {
    my ($case_ret, @values) = @_;
    my %switch = (
        normal => sub { @values },
        die => sub { die ($values[0] . "\n") },
        pending_done => sub { newf },
        pending_fail => sub { newf },
        pending_cancel => sub { newf },
        immediate_done => sub { newf()->fulfill(@values) },
        immediate_fail => sub { newf()->reject(@values) },
        immediate_cancel => sub { newf()->cancel() },
    );
    return $switch{$case_ret}->();
}

test_log_num sub {
    my $f = newf;
    $f->then(sub {});
}, 0, "then() generates no warning in void context";


note("------ cases: start with done -> execute a callback");

foreach my $case_invo (qw(pending_done immediate_done)) {
    foreach my $case_arg ("on_done", "both") {
        foreach my $case_ret ("normal", "immediate_done") {
            test_then_case $case_invo, $case_arg, $case_ret, 0, sub {
                my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
                my $done_executed = 0;
                my $fail_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub {
                    is_deeply(\@_, [1,2,3], "arg OK");
                    $done_executed = 1;
                    return create_return($case_ret, qw(a b c));
                }, sub {
                    $fail_executed = 1;
                });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok(!$done_executed, "done callback not executed");
                    ok($f->is_pending, "f is pending");
                    ok($nf->is_pending, "nf is pending");
                    $f->fulfill(1,2,3);    
                }
                ok($f->is_fulfilled, "f is fulfilled");
                ok($nf->is_fulfilled, "nf is fulfilled");
                is_deeply([$nf->get()], [qw(a b c)], "nf result OK");
                ok($done_executed, "callback executed");
                ok(!$fail_executed, "on_fail callback not executed");
                memory_cycle_ok($f, "f is still free of cyclic ref");
                memory_cycle_ok($nf, "nf is still free of cyclic ref");
            };  
        }
        foreach my $case_ret (qw(die immediate_fail)) {
            test_then_case $case_invo, $case_arg, $case_ret, 1, sub {
                my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
                my $fail_executed = 0;
                my $done_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub {
                    is_deeply(\@_, [1, 2, 3], "then args OK");
                    $done_executed = 1;
                    return create_return($case_ret, qw(a b c));
                }, sub { $fail_executed = 1 });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok(!$done_executed, "done callback not executed");
                    ok($f->is_pending, "f is pending");
                    ok($nf->is_pending, "nf is pending");
                    $f->fulfill(1, 2, 3);    
                }
                ok($done_executed, "done executed");
                ok(!$fail_executed, "fail not executed");
                ok($f->is_fulfilled, "f is fulfilled");
                ok($nf->is_rejected, "nf is rejected");
                is_deeply([$nf->failure], $case_ret eq "die" ? ["a\n"] : [qw(a b c)], "nf failure OK");
                memory_cycle_ok($f, "f is still free of cyclic ref");
                memory_cycle_ok($nf, "nf is still free of cyclic ref");
            };
        }
        test_then_case $case_invo, $case_arg, "pending_done", 0, sub {
            my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
            my $cf = newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $nf = $f->then(filter_callbacks $case_arg, sub {
                is_deeply(\@_, [1, 2, 3], "then args OK");
                $done_executed = 1;
                return $cf;
            }, sub { $fail_executed = 1 });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$done_executed, "done callback not executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->fulfill(1, 2, 3);
            }
            memory_cycle_ok($cf, "cf is free of cyclic ref");
            ok($f->is_fulfilled, "f is fulfilled");
            ok($cf->is_pending, "cf is pending");
            ok($nf->is_pending, "nf is still pending");
            ok($done_executed, "done callback executed");
            ok(!$fail_executed, "fail callback not executed");
            $cf->fulfill(qw(a b c));
            ok($cf->is_fulfilled, "cf is fulfilled");
            ok($nf->is_fulfilled, "nf is fulfilled");
            is_deeply([$nf->get], [qw(a b c)], "nf result OK");
            memory_cycle_ok($f, "f still is free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
            memory_cycle_ok($cf, "cf is still free of cyclic ref");
        };
        test_then_case $case_invo, $case_arg, "pending_fail", 1, sub {
            my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $cf = newf;
            my $nf = $f->then(filter_callbacks $case_arg, sub {
                is_deeply(\@_, [1, 2, 3], "then args OK");
                $done_executed = 1;
                return $cf;
            }, sub { $fail_executed = 1 });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$done_executed, "done callback not yet executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->fulfill(1, 2, 3);    
            }
            memory_cycle_ok($cf, "cf is free of cyclic ref");
            ok($done_executed, "done callback executed");
            ok(!$fail_executed, "fail callback not executed");
            ok($f->is_fulfilled, "f is fulfilled");
            ok($nf->is_pending, "nf is still pending");
            $cf->reject(qw(a b c));
            ok($nf->is_rejected, "nf is rejected");
            is_deeply([$nf->failure], [qw(a b c)], "nf failure OK");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
            memory_cycle_ok($cf, "cf is still free of cyclic ref");
        };
        test_then_case $case_invo, $case_arg, "immediate_cancel", 0, sub {
            my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $nf = $f->then(filter_callbacks $case_arg, sub {
                is_deeply(\@_, [1,2,3], "then args OK");
                $done_executed = 1;
                return newf()->cancel();
            }, sub { $fail_executed = 1 });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$done_executed, "done callback not executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->fulfill(1,2,3);
            }
            ok($f->is_fulfilled, "f is fulfilled");
            ok($done_executed, "done callback executed");
            ok(!$fail_executed, "fail callback not executed");
            ok(!$nf->is_pending, "nf is not pending");
            ok($nf->is_cancelled, "nf is cancelled");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
        };
        test_then_case $case_invo, $case_arg, "pending_cancel", 0, sub {
            my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $cf = newf;
            my $nf = $f->then(filter_callbacks $case_arg, sub {
                is_deeply(\@_, [1,2,3], "then args OK");
                $done_executed = 1;
                return $cf;
            }, sub { $fail_executed = 1 });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$done_executed, "done callback not called yet");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->fulfill(1,2,3);
            }
            memory_cycle_ok($cf, "cf is free of cyclic ref");
            ok($f->is_fulfilled, "f is fulfilled");
            ok($done_executed, "done callback is called");
            ok(!$fail_executed, "fail callback is not called");
            ok($nf->is_pending, "nf is still pending");
            $cf->cancel();
            ok(!$nf->is_pending, "nf is not pending");
            ok($nf->is_cancelled, "nf is cancelled");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
            memory_cycle_ok($cf, "cf is still free of cyclic ref");
        };
    }
}

note("------ cases: start with fail -> execute a callback");

foreach my $case_invo (qw(pending_fail immediate_fail)) {
    foreach my $case_arg ("on_fail", "both") {
        foreach my $case_ret ("normal", "immediate_done") {
            test_then_case $case_invo, $case_arg, $case_ret, 0, sub {
                my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
                my $done_executed = 0;
                my $fail_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub { $done_executed = 1}, sub {
                    is_deeply(\@_, [1,2,3], "then args OK");
                    $fail_executed = 1;
                    return create_return($case_ret, qw(a b c));
                });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok($nf->is_pending, "nf is pending");
                    ok($f->is_pending, "f is pending");
                    ok(!$fail_executed, "fail callback is not executed");
                    $f->reject(1,2,3);
                }
                ok($fail_executed, "fail callback is executed");
                ok(!$done_executed, "done callback is not executed");
                ok($f->is_rejected, "f is rejected");
                ok($nf->is_fulfilled, "nf is fulfilled");
                is_deeply([$nf->get], [qw(a b c)], "nf result OK");
                memory_cycle_ok($f, "f is still free of cyclic ref");
                memory_cycle_ok($nf, "nf is still free of cyclic ref");
            };
        }
        foreach my $case_ret ("die", "immediate_fail") {
            test_then_case $case_invo, $case_arg, $case_ret, 1, sub {
                my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
                my $done_executed = 0;
                my $fail_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub { $done_executed = 1 }, sub {
                    is_deeply(\@_, [1,2,3], "then args OK");
                    $fail_executed = 1;
                    return create_return($case_ret, qw(a b c));
                });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok($f->is_pending, "f is pending");
                    ok($nf->is_pending, "nf is pending");
                    ok(!$fail_executed, "fail callback is not executed");
                    $f->reject(1,2,3);
                }
                ok($fail_executed, "fail callback is executed");
                ok(!$done_executed, "done callback is not executed");
                ok($f->is_rejected, "f is rejected");
                ok($nf->is_rejected, "nf is rejected, too");
                is_deeply([$nf->failure], $case_ret eq "die" ? ["a\n"] : [qw(a b c)], "nf failure OK");
                memory_cycle_ok($f, "f is still free of cyclic ref");
                memory_cycle_ok($nf, "nf is still free of cyclic ref");
            };
        }
        test_then_case $case_invo, $case_arg, "pending_done", 0, sub {
            my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $cf = newf;
            my $nf = $f->then(filter_callbacks $case_arg, sub { $done_executed = 1 }, sub {
                is_deeply(\@_, [1,2,3], "then arg OK");
                $fail_executed = 1;
                return $cf;
            });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$fail_executed, "fail callback not executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->reject(1,2,3);
            }
            memory_cycle_ok($cf, "cf is free of cyclic ref");
            ok($fail_executed, "fail callback executed");
            ok(!$done_executed, "done callback not executed");
            ok($f->is_rejected, "f is rejected");
            ok($nf->is_pending, "nf is still pending");
            $cf->fulfill(qw(a b c));
            ok($nf->is_fulfilled, "nf is fulfilled");
            is_deeply([$nf->get], [qw(a b c)], "nf result OK");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
            memory_cycle_ok($cf, "cf is still free of cyclic ref");
        };
        test_then_case $case_invo, $case_arg, "pending_fail", 1, sub {
            my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $cf = newf;
            my $nf = $f->then(filter_callbacks $case_arg, sub { $done_executed = 1 }, sub {
                is_deeply(\@_, [1,2,3], "then args OK");
                $fail_executed = 1;
                return $cf;
            });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$fail_executed, "fail callback not executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->reject(1,2,3);
            }
            memory_cycle_ok($cf, "cf is free of cyclic ref");
            ok($fail_executed, "fail callback executed");
            ok($f->is_rejected, "f is rejected");
            ok($nf->is_pending, "nf is still pending");
            $cf->reject(qw(a b c));
            ok($nf->is_rejected, "nf is rejected");
            is_deeply([$nf->failure], [qw(a b c)], "nf failure OK");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
            memory_cycle_ok($cf, "cf is still free of cyclic ref");
        };
        test_then_case $case_invo, $case_arg, "immediate_cancel", 0, sub {
            my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $nf = $f->then(filter_callbacks $case_arg, sub { $done_executed = 1 }, sub {
                is_deeply(\@_, [1,2,3], "then args OK");
                $fail_executed = 1;
                return newf()->cancel();
            });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$fail_executed, "fail callback not executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->reject(1,2,3);
            }
            ok($fail_executed, "fail callback executed");
            ok(!$done_executed, "done callback not executed");
            ok($f->is_rejected, "f is rejected");
            ok(!$nf->is_pending, "nf is not pending");
            ok($nf->is_cancelled, "nf is cancelled");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
        };
        test_then_case $case_invo, $case_arg, "pending_cancel", 0, sub {
            my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
            my $done_executed = 0;
            my $fail_executed = 0;
            my $cf = newf;
            my $nf = $f->then(filter_callbacks $case_arg, sub { $done_executed = 1 }, sub {
                is_deeply(\@_, [1,2,3], "then arg OK");
                $fail_executed = 1;
                return $cf;
            });
            isnt_identical($f, $nf, "f and nf are always different objects.");
            memory_cycle_ok($f, "f is free of cyclic ref");
            memory_cycle_ok($nf, "nf is free of cyclic ref");
            if(not is_immediate($case_invo)) {
                ok(!$fail_executed, "fail callback not executed");
                ok($f->is_pending, "f is pending");
                ok($nf->is_pending, "nf is pending");
                $f->reject(1,2,3);
            }
            memory_cycle_ok($cf, "cf is free of cyclic ref");
            ok($fail_executed, "fail callback executed");
            ok(!$done_executed, "done callback not executed");
            ok($f->is_rejected, "f is rejected");
            ok($nf->is_pending, "nf is still pending");
            $cf->cancel();
            ok(!$nf->is_pending, "nf is not pending anymore");
            ok($nf->is_cancelled, "nf is cancelled");
            memory_cycle_ok($f, "f is still free of cyclic ref");
            memory_cycle_ok($nf, "nf is still free of cyclic ref");
            memory_cycle_ok($cf, "cf is still free of cyclic ref");
        };
    }
}

note("------ cases: start with done -> no catching callback");
foreach my $case_invo (qw(pending_done immediate_done)) {
    foreach my $case_arg ("on_fail", "none") {
        foreach my $case_ret (@CASES_RETURN) {
            test_then_case $case_invo, $case_arg, $case_ret, 0, sub {
                my $f = is_immediate($case_invo) ? newf()->fulfill(1,2,3) : newf;
                my $fail_executed = 0;
                my $done_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub {
                    $done_executed = 1;
                    return create_return($case_ret, qw(a b c));
                }, sub {
                    $fail_executed = 1;
                    return create_return($case_ret, qw(a b c));
                });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok($f->is_pending, "f is pending");
                    ok($nf->is_pending, "nf is pending");
                    $f->fulfill(1,2,3);
                }
                ok(!$fail_executed, "fail callback is not executed");
                ok(!$done_executed, "done callback is not executed");
                ok($nf->is_fulfilled, "nf is fulfilled");
                is_deeply([$nf->get], [1,2,3], "nf result OK");
                memory_cycle_ok($f, "f is still free of cyclic ref");
                memory_cycle_ok($nf, "nf is still free of cyclic ref");
            };
        }
    }
}

note("------ cases: start with fail -> no catching callback");
foreach my $case_invo (qw(pending_fail immediate_fail)) {
    foreach my $case_arg ("on_done", "none") {
        foreach my $case_ret (@CASES_RETURN) {
            test_then_case $case_invo, $case_arg, $case_ret, 1, sub {
                my $f = is_immediate($case_invo) ? newf()->reject(1,2,3) : newf;
                my $done_executed = 0;
                my $fail_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub {
                    $done_executed = 1;
                    return create_return($case_ret, qw(a b c));
                }, sub {
                    $fail_executed = 1;
                    return create_return($case_ret, qw(a b c));
                });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok($f->is_pending, "f is pending");
                    ok($nf->is_pending, "nf is pending");
                    $f->reject(1,2,3);
                }
                ok(!$done_executed, "done callback is not executed");
                ok(!$fail_executed, "fail callback is not executed");
                ok($nf->is_rejected, "nf is rejected");
                is_deeply([$nf->failure], [1,2,3], "nf failure OK");
                memory_cycle_ok($f, "f is still free of cyclic ref");
                memory_cycle_ok($nf, "nf is still free of cyclic ref");
            };
        }
    }
}

note("------ cases: start with cancel -> not execute callback");
foreach my $case_invo (qw(pending_cancel immediate_cancel)) {
    foreach my $case_arg (@CASES_ARGS) {
        foreach my $case_ret (@CASES_RETURN) {
            test_then_case $case_invo, $case_arg, $case_ret, 0, sub {
                my $f = is_immediate($case_invo) ? newf()->cancel : newf;
                my $done_executed = 0;
                my $fail_executed = 0;
                my $nf = $f->then(filter_callbacks $case_arg, sub {
                    $done_executed = 1;
                    return create_return($case_ret, qw(a b c));
                }, sub {
                    $fail_executed = 1;
                    return create_return($case_ret, qw(a b c));
                });
                isnt_identical($f, $nf, "f and nf are always different objects.");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
                if(not is_immediate($case_invo)) {
                    ok(!$done_executed, "done callback not executed");
                    ok(!$fail_executed, "fail callback not executed");
                    ok($f->is_pending, "f is pending");
                    ok($nf->is_pending, "nf is pending");
                    $f->cancel();
                }
                ok(!$done_executed, "done callback not executed");
                ok(!$fail_executed, "fail callback not executed");
                ok($f->is_cancelled, "f is cancelled");
                ok(!$nf->is_pending, "nf is not pending");
                ok($nf->is_cancelled, "nf is cancelled");
                memory_cycle_ok($f, "f is free of cyclic ref");
                memory_cycle_ok($nf, "nf is free of cyclic ref");
            };
        }
    }
}


note("--- check if untested cases exist.");
foreach my $key (sort {$a cmp $b} keys %tested_case) {
    is($tested_case{$key}, 1, "Case $key is tested once.");
}

done_testing();

