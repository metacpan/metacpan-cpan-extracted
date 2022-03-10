package   # CPAN, don't index
    TestHelper;

BEGIN { $^P = 0x400 }  # Turn on source code saving into @main::{"_<$filename"}

use strict;
use warnings;

use Test2::V0;
use Test2::API 1.302136 qw( context_do context run_subtest test2_add_callback_testing_done);
use base 'Devel::Chitin';
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(ok_location ok_breakable ok_not_breakable ok_trace_location
                    ok_set_breakpoint ok_breakpoint ok_change_breakpoint ok_delete_breakpoint
                    ok_set_action ok_uncaught_exception ok_subroutine_location
                    ok_add_watchexpr ok_watched_expr_notification
                    ok_at_end
                    is_eval is_eval_exception is_var_at_level
                    do_test do_disable_auto_disable
                    db_step db_continue db_continue_to db_stepout db_stepover db_trace db_disable
                    has_callsite
                );

my @TEST_QUEUE;

test2_add_callback_testing_done(sub {
    if (@TEST_QUEUE) {
        ok(0, 'There were ' . scalar(@TEST_QUEUE) . ' tests remaining in the queue');
    }
});

sub init {
    main::__tests__();
}

sub guard(&) {
    my $code = shift;
    bless $code, 'Devel::Chitin::TestHelper::Guard';
}
sub Devel::Chitin::TestHelper::Guard::DESTROY {
    my $code = shift;
    $code->();
}

my $START_TESTING = 0;
our $AT_END = 0;
my $IS_STOPPED = 0;
my $CONTINUE_AFTER_TEST_QUEUE_IS_EMPTY = 0;
sub notify_stopped {
    return unless $START_TESTING;

    my $guard = guard { $IS_STOPPED = 0 };
    $IS_STOPPED = 1;

    my($self, $location) = @_;

    if (substr($location->subroutine, -5) eq '::END') {
        # If we're running END blocks, then we're at the end.
        # Note that the Test2 framework's END blocks run before the debugger's
        $AT_END = 1;
    }

    unless (@TEST_QUEUE) {
        my $ctx = context();
        $ctx->fail(sprintf('Stopped at %s:%d with no tests remaining in the queue', $location->filename, $location->line));
        $ctx->release;
        __PACKAGE__->disable_debugger();
        return;
    }

    TEST_QUEUE_LOOP:
    while(my $test = shift @TEST_QUEUE) {
        $test->($location);
    }

    __PACKAGE__->disable_debugger unless (@TEST_QUEUE or $CONTINUE_AFTER_TEST_QUEUE_IS_EMPTY);
}


sub _run_one_test {
    my($location, $kind, @additional) = @_;

    unless (@TEST_QUEUE) {
        my $ctx = context();
        $ctx->fail(sprintf('%s() at %s:%d with no tests remaining in the queue', $kind, $location->filename, $location->line));
        $ctx->release;
        __PACKAGE__->disable_debugger();
        return;
    }

    my $test = shift @TEST_QUEUE;
    $test->($location, @additional);

    __PACKAGE__->disable_debugger unless (@TEST_QUEUE);
    1;
}

my $IS_TRACE = 0;
sub notify_trace {
    my($self, $location) = @_;

    my $guard = guard { $IS_TRACE = 0 };
    $IS_TRACE=1;

    _run_one_test($location, 'notify_trace');
}

my $IS_EXCEPTION = 0;
sub notify_uncaught_exception {
    my($self, $exception) = @_;

    my $guard = guard { $IS_EXCEPTION = 0 };
    $IS_EXCEPTION = 1;

    unless (_run_one_test($exception, 'notify_uncaught_exception')) {
        print STDERR "exception was: ", $exception->exception;
    }
    $? = 0;
}

my $IS_WATCH_NOTIFICATION = 0;
sub notify_watch_expr {
    my($self, $location, $expr, $old, $new) = @_;

    my $guard = guard { $IS_WATCH_NOTIFICATION = 0 };
    $IS_WATCH_NOTIFICATION = 1;

    _run_one_test($location, 'notify_watch_expr', $expr, $old, $new);
}

# test-like functions

sub _test_location_contents {
    my($location, %params) = @_;
    foreach my $key ( keys %params ) {
        if (ref($params{$key}) eq 'Regexp') {
            like($location->$key, $params{$key}, $key);
        } else {
            is($location->$key, $params{$key}, $key);
        }
    }
}

sub _test_location {
    my($check_flag_ref, $check_flag_label, %params) = @_;

    my $from_line = (caller(1))[2];

    my $test = sub {
        my $location = shift;
        my $subtest = sub {
            unless ($$check_flag_ref) {
                fail("Checking location when debugger is not $check_flag_label");
                return;
            }
            _test_location_contents($location, %params);
        };

        context_do {
            run_subtest("$check_flag_label location($from_line)", $subtest);
        }
    };
    push @TEST_QUEUE, $test;
}

sub ok_location {
    _test_location(\$IS_STOPPED, 'stopped', @_);
}

sub ok_trace_location {
    _test_location(\$IS_TRACE, 'traced', @_);
}

sub ok_uncaught_exception {
    _test_location(\$IS_EXCEPTION, 'stopped in exception', @_);
}

sub ok_watched_expr_notification {
    my %params = @_;

    unless (exists $params{expr} and exists $params{old} and exists $params{new}) {
        die "'expr', 'old' and 'new' are required args to ok_watched_expr";
    }
    my $expected_expr = delete $params{expr};
    my $expected_old = delete $params{old};
    my $expected_new = delete $params{new};

    push @TEST_QUEUE, sub {
        my($location, $expr, $old, $new) = @_;
        run_subtest("notifying changed expr $expected_expr", sub {
            unless ($IS_WATCH_NOTIFICATION) {
                fail('Cheching for watched expr change when no notification was received');
                return;
            }
            _test_location_contents($location, %params);
            is($expr, $expected_expr, 'expr');
            is($old, $expected_old, 'old value');
            is($new, $expected_new, 'new value');
        });
    };
}

sub ok_subroutine_location {
    my($subname, %params) = @_;
    push @TEST_QUEUE, sub {
        my $sublocation = __PACKAGE__->subroutine_location($subname);
        my $subtest = sub {
            _test_location_contents($sublocation, %params);
        };

        context_do {
            run_subtest("subroutine_location for $subname", $subtest);
        };
    };
}

sub ok_breakpoint {
    my %params = @_;

    my($file, $from_line) = (caller)[1, 2];
    $params{file} = $file unless exists ($params{file});
    my $bp_line = $params{line};

    my $subtest = sub {
        my @bp = Devel::Chitin::Breakpoint->get(%params);
        if (@bp != 1) {
            fail("Expected 1 breakpoint in ok_breakpoint($from_line), but got ".scalar(@bp));
        }

        ok($bp[0], 'Got breakpoint');
        foreach my $attr ( keys %params ) {
            is($bp[0]->$attr, $params{$attr}, $attr);
        }
    };
    push @TEST_QUEUE, sub {
        context_do {
            run_subtest("breakpoint($from_line) ${file}:${bp_line}", $subtest);
        }
    };
}

sub ok_at_end {
    my $from_line = (caller)[2];

    my $test = sub {
        context_do {
            my $ctx = shift;
            $ctx->ok($AT_END, "at_end($from_line)");
        };

        __PACKAGE__->disable_debugger if (! @TEST_QUEUE and $AT_END);
    };
    push @TEST_QUEUE, $test;
}

sub ok_breakable {
    my($file, $line) = @_;
    my $from_line = (caller)[2];

    my $test = sub {
        context_do {
            my $ctx = shift;
            $ctx->ok( __PACKAGE__->is_breakable($file, $line), "${file}:${line} is breakable");
        };
    };
    push @TEST_QUEUE, $test;
}

sub ok_not_breakable {
    my($file, $line) = @_;

    my $test = sub {
        context_do {
            my $ctx = shift;
            $ctx->ok( ! __PACKAGE__->is_breakable($file, $line), "${file}:${line} is not breakable");
        };
    };
    push @TEST_QUEUE, $test;
}

sub ok_add_watchexpr {
    my($expr, $comment) = @_;

    my $test = sub {
        context_do {
            my $ctx = shift;
            $ctx->ok( __PACKAGE__->add_watchexpr($expr), $comment);
        };
    };
    push @TEST_QUEUE, $test;
}

sub ok_set_action {
    my $comment = pop;
    my %params = @_;

    $params{file} = (caller)[1] unless exists $params{file};

    my $test = sub {
        context_do {
            my $ctx = shift;
            $ctx->ok( Devel::Chitin::Action->new(%params), $comment);
        };
    };
    push @TEST_QUEUE, $test;
}

sub ok_set_breakpoint {
    my $comment = pop;
    my %params = @_;

    $params{file} = (caller)[1] unless exists $params{file};

    my $test = sub {
        context_do {
            my $ctx = shift;
            $ctx->ok( Devel::Chitin::Breakpoint->new(%params), $comment);
        };
    };
    push @TEST_QUEUE, $test;
}

sub ok_change_breakpoint {
    my $comment = pop;
    my %params = @_;

    my $changes = delete $params{change};
    unless (ref($changes) eq 'HASH') {
        Carp::croak("'change' is a required param to ok_change_breakpoint(), and must be a hashref");
    }

    my $test = sub {
        context_do {
            my $ctx = shift;

            my @bp = Devel::Chitin::Breakpoint->get(%params);
            unless (@bp) {
                $ctx->fail('params matched no breakpoints: ', join(', ', map { "$_ => ".$params{$_} } keys(%params)));
            }
            foreach my $bp ( @bp ) {
                foreach my $param (keys %$changes) {
                    $bp->$param($changes->{$param});
                }
                $ctx->pass(sprintf('%s at %s:%d', $comment, $bp->file, $bp->line));
            }
        };
    };
    push @TEST_QUEUE, $test;
}

sub ok_delete_breakpoint {
    my $comment = pop;
    my %params = @_;

    my $test = sub {
        context_do {
            my $ctx = shift;

            my @bp = Devel::Chitin::Breakpoint->get(%params);
            foreach my $bp ( @bp ) {
                $ctx->ok($bp->delete, sprintf('Delete breakpoint at %s:%d', $bp->file, $bp->line));
            }
        };
    };
    push @TEST_QUEUE, $test;
}

sub do_test(&) {
    push @TEST_QUEUE, shift();
}

sub is_var_at_level {
    my($var_expr, $level, $expected, $msg) = @_;

    push @TEST_QUEUE, sub {
        is(__PACKAGE__->get_var_at_level($var_expr, $level),
            $expected,
            $msg);
    };
}

sub do_disable_auto_disable {
    push @TEST_QUEUE, sub {
        $CONTINUE_AFTER_TEST_QUEUE_IS_EMPTY = 1;
    }
}

# Debugger control functions

sub db_step {
    push @TEST_QUEUE, sub {
        __PACKAGE__->step;
        no warnings 'exiting';
        last TEST_QUEUE_LOOP;
    };
}

sub db_continue {
    push @TEST_QUEUE, sub {
        __PACKAGE__->continue;
        no warnings 'exiting';
        last TEST_QUEUE_LOOP;
    }
}

sub db_continue_to {
    my @params = @_;

    push @TEST_QUEUE, sub {
        __PACKAGE__->continue_to( @params );
        no warnings 'exiting';
        last TEST_QUEUE_LOOP;
    }
}

sub db_stepout {
    my @args = @_;
    push @TEST_QUEUE, sub {
        __PACKAGE__->stepout(@args);
        no warnings 'exiting';
        last TEST_QUEUE_LOOP;
    }
}

sub db_stepover {
    push @TEST_QUEUE, sub {
        __PACKAGE__->stepover;
        no warnings 'exiting';
        last TEST_QUEUE_LOOP;
    }
}

sub db_trace {
    my $val = shift;
    push @TEST_QUEUE, sub {
        __PACKAGE__->trace($val);
    }
}

sub db_disable {
    push @TEST_QUEUE, sub {
        __PACKAGE__->disable_debugger;
    }
}

my $should_poll = 0;
sub poll { $should_poll }
sub is_eval {
    my($code_string, $wantarray, $expected, $msg) = @_;
    _make_eval_tester($code_string, $wantarray, $expected, '', $msg);
}

sub is_eval_exception {
    my($code_string, $wantarray, $expected_exception, $msg) = @_;
    _make_eval_tester($code_string, $wantarray, undef, $expected_exception, $msg);
}

sub _make_eval_tester {
    my($code_string, $wantarray, $expected_value, $expected_exception, $msg) = @_;

    my($expected_value_msg, $expected_exception_msg) = $expected_exception
            ? ( 'eval-ed undef', 'exception' )
            : ( 'eval value', 'no exception' );
    push @TEST_QUEUE, sub {
        ++$should_poll;
        __PACKAGE__->eval($code_string, $wantarray,
            sub {
                my($got, $exception) = @_;
                $should_poll--;
                context_do {
                    run_subtest($msg, sub {
                        is($got, $expected_value, $expected_value_msg);
                        like($exception, $expected_exception, $expected_exception_msg);
                    });
                };
            }
        )
    };
}

my $has_callsite;
sub has_callsite {
    unless (defined $has_callsite) {
        my $test_callsite = ( sub { Devel::Chitin::Location::get_callsite(0) })->();
        $has_callsite = !! $test_callsite;
    }
    $has_callsite;
}

__PACKAGE__->attach();

BEGIN { $^P = 0x73f }  # Turn on all the debugging stuff
INIT { $START_TESTING = 1 }
