use strict;
use warnings;
use Test::More;
use Future::Q;

note("--- execution order of parallel then() callbacks (both on_fulfilled and on_rejected). They should be called in the order of then() calls.");

foreach my $case (qw(immediate pending)) {
    note("--- $case fulfill");
    my $f = Future::Q->new;
    if($case eq "immediate") {
        $f->fulfill(10);
    }
    my @result = ();
    foreach my $i (0 .. 3) {
        $f->then(sub { push @result, $_[0] + $i });
    }
    if($case ne "immediate") {
        $f->fulfill(10);
    }
    is_deeply \@result, [10, 11, 12 ,13], "$case: order of on_fulfilled callbacks OK";
}

foreach my $case (qw(immediate pending)) {
    note("--- $case reject");
    my $f = Future::Q->new;
    if($case eq "immediate") {
        $f->reject(10);
    }
    my @result = ();
    my @result_futures = ();
    foreach my $i (0 .. 3) {
        push @result_futures, $f->catch(sub { push @result, $_[0] + $i });
    }
    if($case ne "immediate") {
        $f->reject(10);
    }
    is_deeply \@result, [10, 11, 12, 13], "$case: order of on_rejected callbacks OK";
    $_->catch(sub {}) foreach @result_futures;  ## mark error handled.
}

done_testing;

