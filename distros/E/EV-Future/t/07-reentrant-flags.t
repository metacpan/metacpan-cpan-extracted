use strict;
use warnings;
use Test::More;
use EV::Future;

{
    package EVF::Flag;
    sub TIESCALAR { bless { call => $_[1], value => $_[2] }, $_[0] }
    sub FETCH { $_[0]{call}->(); $_[0]{value} }
}

my @series = (
    [series => sub { series([($_[0]) x 2], $_[1], $_[2]) }],
    [series_map => sub {
        my $task = $_[0];
        series_map([1, 2], sub { $task->($_[1]) }, $_[1], $_[2]);
    }],
);

for my $case (@series) {
    my ($name, $start) = @$case;
    for my $unsafe (0, 1) {
        for my $value (0, 1) {
            for my $fire (0, 1) {
                subtest "$name done flag cancels ($unsafe, $value, $fire)" => sub {
                    my ($done, $calls, $final) = (undef, 0, 0);
                    my $h = $start->(sub { $calls++; $done = shift },
                                    sub { $final++ }, $unsafe);
                    tie my $flag, 'EVF::Flag', sub { $h->cancel($fire) }, $value;
                    $done->($flag);
                    $done->();

                    is($calls, 1, 'remaining task was not dispatched');
                    is($final, $fire, 'only cancel decides whether final_cb fires');
                    is($h->pending, 0, 'operation is over');
                    is($h->active, 0, 'no task remains active');
                };
            }
        }
    }
}

my @cases = (
    [parallel => sub { parallel([$_[0]], $_[1], $_[2]) }],
    [parallel_limit => sub { parallel_limit([$_[0]], 1, $_[1], $_[2]) }],
    @series,
    [race => sub { race([$_[0]], $_[1], $_[2]) }],
    [parallel_map => sub {
        my $task = $_[0];
        parallel_map([1], sub { $task->($_[1]) }, $_[1], $_[2]);
    }],
    [parallel_map_limit => sub {
        my $task = $_[0];
        parallel_map_limit([1], sub { $task->($_[1]) }, 1, $_[1], $_[2]);
    }],
);

for my $case (@cases) {
    my ($name, $start) = @$case;
    for my $unsafe (0, 1) {
        subtest "$name cancel flag releases the handle ($unsafe)" => sub {
            my (@done, @warnings);
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            my $final = 0;
            my $h = $start->(sub { push @done, shift }, sub { $final++ }, $unsafe);
            tie my $flag, 'EVF::Flag', sub { $h->cancel; undef $h }, 1;
            $h->cancel($flag);
            $_->() for @done;

            ok(!defined $h, 'flag evaluation released the handle');
            is($final, 0, 'late done did not fire final_cb');
            is_deeply(\@warnings, [], 'handle released without refcount warnings');
        };
    }
}

done_testing;
