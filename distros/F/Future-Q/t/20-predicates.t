use strict;
use warnings;
use Test::More;
use Future::Q;
use Test::Builder;

note("----- tests for predicate methods");

sub test_predicates {
    my ($f, %exp_predicates) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    foreach my $pred (keys %exp_predicates) {
        my $exp_state = $exp_predicates{$pred};
        my $method = "is_$pred";
        if($exp_state) {
            ok($f->$method, "future is $pred");
        }else {
            ok(!$f->$method, "future is not $pred");
        }
    }
}

{
    note("--- pending future");
    my $f = Future::Q->new;
    test_predicates(
        $f, pending => 1, fulfilled => 0,
        rejected => 0, cancelled => 0
    );
    $f->fulfill();
}

{
    note("--- fulfilled future");
    my $f = Future::Q->new;
    $f->fulfill();
    test_predicates(
        $f, pending => 0, fulfilled => 1,
        rejected => 0, cancelled => 0
    );
}

{
    note("--- rejected future");
    my $f = Future::Q->new;
    $f->reject("error");
    test_predicates(
        $f, pending => 0, fulfilled => 0,
        rejected => 1, cancelled => 0
    );
    $f->catch(sub {  });
}

{
    note("--- cancelled future");
    my $f = Future::Q->new;
    $f->cancel();
    test_predicates(
        $f, pending => 0, fulfilled => 0,
        rejected => 0, cancelled => 1
    );
}

done_testing();
