use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use EV::Future;

{
    package EVF::FalseError;
    use overload bool => sub { 0 }, '""' => sub { 'task failed' }, fallback => 1;
}

my @cases = (
    [parallel => sub { parallel([($_[0]) x 2], $_[1], $_[2]) }],
    [parallel_limit => sub { parallel_limit([($_[0]) x 2], 1, $_[1], $_[2]) }],
    [series => sub { series([($_[0]) x 2], $_[1], $_[2]) }],
    [race => sub { race([($_[0]) x 2], $_[1], $_[2]) }],
    [parallel_map => sub {
        my $task = $_[0];
        parallel_map([1, 2], sub { $task->($_[1]) }, $_[1], $_[2]);
    }],
    [parallel_map_limit => sub {
        my $task = $_[0];
        parallel_map_limit([1, 2], sub { $task->($_[1]) }, 1, $_[1], $_[2]);
    }],
    [series_map => sub {
        my $task = $_[0];
        series_map([1, 2], sub { $task->($_[1]) }, $_[1], $_[2]);
    }],
);

for my $case (@cases) {
    my ($name, $start) = @$case;

    subtest "$name preserves false exception objects" => sub {
        my ($late, $calls, $final) = (undef, 0, 0);
        my $error = bless {}, 'EVF::FalseError';
        my $ok = eval {
            $start->(sub {
                $calls++;
                $late = shift;
                die $error;
            }, sub { $final++ }, 0);
            1;
        };
        my $caught = $@;

        ok(!$ok, 'exception propagated');
        is(refaddr($caught), refaddr($error), 'original exception object preserved');
        is($calls, 1, 'dispatch stopped after the failed task');
        $late->();
        is($calls, 1, 'late done cannot resume dispatch');
        is($final, 0, 'late done cannot fire final_cb');
    };

    for my $unsafe (0, 1) {
        for my $cancel (0, 1) {
            subtest "$name retains final_cb ($unsafe, cancel=$cancel)" => sub {
                my (@done, $final, $wrong);
                my $cb = sub { $final++ };
                my $h = $start->(sub { push @done, shift }, $cb, $unsafe);
                $cb = sub { $wrong++ };

                $h->cancel(1) if $cancel;
                while (my $d = shift @done) { $d->() }

                is($final, 1, 'captured callback fired once');
                ok(!$wrong, 'reassigned callback was not called');
                is($h->pending, 0, 'operation is over');
            };
        }
    }
}

my @maps = (
    [parallel_map => sub { parallel_map($_[0], $_[1], $_[2], $_[3]) }],
    [parallel_map_limit => sub { parallel_map_limit($_[0], $_[1], 1, $_[2], $_[3]) }],
    [series_map => sub { series_map($_[0], $_[1], $_[2], $_[3]) }],
);

for my $case (@maps) {
    my ($name, $start) = @$case;
    for my $unsafe (0, 1) {
        for my $sync (0, 1) {
            subtest "$name retains worker ($unsafe, sync=$sync)" => sub {
                my (@seen, @done, $worker, $final);
                $worker = sub {
                    push @seen, $_[0];
                    if ($sync) {
                        undef $worker;
                        $_[1]->();
                    } else {
                        push @done, $_[1];
                    }
                };
                my $h;
                my $ok = eval {
                    $h = $start->([1, 2, 3], $worker, sub { $final++ }, $unsafe);
                    undef $worker;
                    while (my $d = shift @done) { $d->() }
                    1;
                };
                ok($ok, 'releasing the worker does not interrupt dispatch') or diag "$@";
                is_deeply(\@seen, [1, 2, 3], 'captured worker processed every item');
                is($final, 1, 'final_cb fired once');
                $h->cancel if defined $h;
            };
        }

        subtest "$name aliases sparse elements ($unsafe)" => sub {
            my @items;
            $items[2] = 'last';
            my ($i, $final) = (0, 0);
            my $ok = eval {
                $start->(\@items, sub { $_[0] = ++$i; $_[1]->() },
                         sub { $final++ }, $unsafe);
                1;
            };
            ok($ok, 'holes are writable through the worker argument') or diag "$@";
            is_deeply(\@items, [1, 2, 3], 'assignments update the original elements');
            is($final, 1, 'final_cb fired once');
        };
    }
}

done_testing;
